# plated — plate detection service

The network half of AI food logging. The app photographs a plate once per thing
added to it, posts the whole batch here, and this service asks a vision model
through [OpenRouter](https://openrouter.ai) which foods are on it.

It exists for two reasons:

- **The OpenRouter key stays server-side.** A key compiled into the app ships
  inside the binary and any user can extract it.
- **The model is a deployment knob.** `OPENROUTER_MODEL` re-points the detector
  with a restart and no client release.

Everything else in `healthapp` is offline-first. This is the one path that needs
the network, and only between the shutter and the plate — confirming a plate
writes to local SQLite and never comes back here.

## Deduplication is the contract

Every shutter press resends **every photo of the current meal**, not just the new
one. That is the whole design: a detector that only ever sees one photo cannot
tell "the same chicken thigh again" from "a second chicken thigh", so
deduplication has to happen where the whole batch is visible at once.

The model assigns each physical food item a stable `instance_id` and reuses it
for that item in every shot it appears in, so a chicken thigh photographed four
times comes back as **one** item carrying `"shots": [1,2,3,4]`. The app merges on
that id, and one physical item becomes one `log_entries` row.

`normalize.go` then enforces the invariant rather than trusting it, because a
model that slips here double-logs someone's dinner:

| Slip | Repair |
| --- | --- |
| same id twice in one reply | collapsed to one entry, shot lists unioned |
| new id for food the request already staged | adopts the staged id, unless that id also appears on its own account |
| `Chicken_1` vs `chicken-1` | slugified, so they are the same id |
| shots out of range, repeated, unsorted, or empty | bounded, deduplicated, sorted; empty becomes the newest shot |
| grams outside 1–2000, or NaN | `0`, meaning "no estimate" — the app falls back to the food's serving weight |
| negative energy or macros | clamped to 0, so the `custom_foods` CHECKs accept them |

Two separate items of one food are *not* merged: two fried eggs are `egg_1` and
`egg_2`, two rows, two entries. The alias repair only fires on an id the reply
did not otherwise claim.

## Run it

```bash
cd server
export OPENROUTER_API_KEY=sk-or-v1-...
export PLATE_API_TOKEN=$(openssl rand -hex 32)   # see "Authentication"
go run .
```

```bash
go vet ./...     # clean
go test ./...    # all green, offline — no key needed, OpenRouter is stubbed
gofmt -l .       # silent
```

The tests never reach the network: `httptest` stands in for OpenRouter, so the
suite runs on a laptop with no credentials.

## Configuration

| variable | default | notes |
| --- | --- | --- |
| `OPENROUTER_API_KEY` | — | Empty is **normal**: detection answers `not_configured` and the app hides the mode. |
| `OPENROUTER_MODEL` | `google/gemini-2.5-flash` | Any multimodal OpenRouter id that supports structured outputs. |
| `ALLOW_MODEL_OVERRIDE` | `false` | Lets a request pick the model. Leave off in production — callers would choose what you are billed for. |
| `PLATE_API_TOKEN` | — | Shared secret required as `Authorization: Bearer …`. Empty leaves the endpoint open. |
| `ADDR` / `PORT` | `:8080` | `PORT` alone is honoured for platforms that inject it. |
| `OPENROUTER_ENDPOINT` | OpenRouter's chat-completions URL | Must be HTTPS, or loopback HTTP for tests. |
| `OPENROUTER_TIMEOUT` | `24s` | **Total** budget including the one resend. Deliberately under the app's 30 s ceiling so the app gets a described failure instead of giving up first. |
| `OPENROUTER_TEMPERATURE` | `0` | |
| `OPENROUTER_MAX_TOKENS` | `2048` | |
| `MAX_SHOTS` | `8` | The app caps at the same number; this is the copy a caller cannot edit. |
| `MAX_REQUEST_BYTES` | `25165824` | 8 shots of 1024 px JPEG land near 3 MB. |
| `OPENROUTER_REFERER`, `OPENROUTER_TITLE` | — | OpenRouter attribution headers. |

## Authentication

**`PLATE_API_TOKEN` is optional and the service starts without it, but an
unauthenticated deployment spends your OpenRouter credit for anyone who finds
the URL.** Startup logs a warning when it is unset. Either set it, or keep the
service off the public internet.

The token is compared in constant time. It is a shared secret, not user
identity — this service has no notion of a user, and nothing it stores or
returns is per-user.

## API

### `POST /v1/plate/detect`

```jsonc
{
  "shots": ["<base64 JPEG>", "..."],   // shot 1 first; a data: prefix is fine
  "plate": [                            // currently staged items, may be omitted
    { "instance_id": "chicken_1", "name": "Chicken thigh", "grams": 140 }
  ],
  "model": "vendor/model"               // only with ALLOW_MODEL_OVERRIDE
}
```

`200`:

```jsonc
{
  "model": "google/gemini-2.5-flash",
  "items": [
    {
      "instance_id": "chicken_1",
      "name": "Grilled chicken thigh",
      "search_term": "chicken thigh",   // for the USDA catalog lookup, client-side
      "grams": 140,                      // 0 means "no estimate"
      "confidence": 0.94,
      "shots": [1, 2, 3, 4],             // renders as `↺ 4 · counted once`
      "emoji": "🍗",
      "kcal_100g": 209, "protein_100g": 26, "carb_100g": 0, "fat_100g": 11
    }
  ]
}
```

`items: []` is a real answer — no food in these shots — and is never retried.

Nutrition comes back on every item but is only a **fallback**: the app first
tries to resolve `search_term` against the bundled USDA catalog, which carries
the full 50-nutrient vector. The model's four macros are used only when no
catalog row clears the match threshold.

### Errors

Switch on `error.code`, not the status: several failures share a status and each
one gets different copy on the camera pane.

| code | status | meaning |
| --- | --- | --- |
| `bad_request` | 400 | Malformed body, no shots, too many shots, not base64, not a JPEG, or a refused model override. |
| `unauthorized` | 401 | `PLATE_API_TOKEN` is set and the bearer token did not match. |
| `not_configured` | 503 | No `OPENROUTER_API_KEY`. |
| `no_connection` | 502 | OpenRouter unreachable. |
| `timeout` | 504 | The budget expired. |
| `unreadable` | 502 | Two replies in a row failed schema validation. |
| `upstream_error` | 502 | OpenRouter answered non-2xx; the upstream status is in `error.status`. |
| `internal` | 500 | Anything else. |

An unreadable reply is resent **once**. Network, timeout and HTTP failures are
never resent — they will not answer differently inside one request, and the app
already offers a retry control the user drives.

### `GET /healthz`

```json
{"status":"ok","configured":true,"model":"google/gemini-2.5-flash","max_shots":8}
```

`configured` reports whether a key is present, never what it is, so a deploy can
be checked before the secret is wired up.

## What never leaves and never lands

- **Photos are transient.** They arrive in a request body, go to OpenRouter, and
  are dropped when the handler returns. Nothing is written to disk and no
  request body is logged.
- **The key is structurally uncopyable into an error.** `upstreamError` carries a
  status code and no body, because an OpenRouter error body can echo the request
  back. `TestNoFailureCarriesTheAPIKey` and `TestDetectEndpointNeverEchoesTheKey`
  drive every failure path with a marked key and assert it never appears.
- **Logs carry counts, not content**: model id, shot count, item count, how many
  items merged, and elapsed ms.

## Pointing the app at it

```bash
flutter run \
  --dart-define=PLATE_API_URL=https://plated.example.com \
  --dart-define=PLATE_API_TOKEN=<the same shared secret>
```

An empty `PLATE_API_URL` means "AI logging disabled", and the app hides the mode
rather than showing a button that always fails.
