# Deploying

Two independent pipelines, plus a one-time GCP bootstrap.

| Workflow | Trigger | Does |
| --- | --- | --- |
| `.github/workflows/ci.yml` | every push and PR | `flutter analyze`/`test`, `gofmt`/`go vet`/`go test`, `terraform fmt`/`validate` |
| `.github/workflows/server-deploy.yml` | push to `main` touching `server/**` or `infra/terraform/app/**` | image → Artifact Registry → Cloud Run, then smoke-tests `/healthz` |
| `.github/workflows/flutter-release.yml` | manual, or a `v*` tag | Shorebird patch **or** release, publishes APK + AAB |

---

## One-time GCP bootstrap

`infra/terraform/bootstrap` holds the things CI cannot create for itself: the state bucket, the
GitHub Workload Identity Federation (WIF) OIDC trust, the Artifact Registry repository, and the deploy service account. Apply it once, by hand, with admin credentials.

```bash
cd infra/terraform/bootstrap
terraform init
terraform apply -var gcp_project_id=YOUR_PROJECT_ID   # override -var name_prefix=… if needed
terraform output github_secrets
```

Its state is local and **not** committed. Losing it is recoverable — every resource is named
deterministically, so a fresh `apply` after `terraform import` picks the same names back up.

## GitHub secrets

`terraform output github_secrets` prints the GCP secrets needed for CI.

| Secret | Used by | Notes |
| --- | --- | --- |
| `GCP_PROJECT_ID` | server-deploy | e.g. `my-gcp-project` |
| `GCP_REGION` | server-deploy | e.g. `us-central1` |
| `WORKLOAD_IDENTITY_PROVIDER` | server-deploy | OIDC provider resource name |
| `GCP_DEPLOY_SERVICE_ACCOUNT` | server-deploy | Deploy service account email |
| `GCP_TF_STATE_BUCKET` | server-deploy | GCS bucket name for the app stack backend |
| `PLATE_API_TOKEN` | **both** | Cloud Run env var *and* the app's dart-define. One value, both places. |
| `PLATE_API_URL` | flutter-release | the Cloud Run URL, available after the first deploy |
| `OPENROUTER_API_KEY` | server-deploy | optional; only needed if targeting openrouter provider models |

| `SHOREBIRD_TOKEN` | flutter-release | Shorebird console → Account → API Keys |
| `ANDROID_KEYSTORE_BASE64` | flutter-release | see below |
| `ANDROID_KEYSTORE_PASSWORD` | flutter-release | |
| `ANDROID_KEY_ALIAS` | flutter-release | |
| `ANDROID_KEY_PASSWORD` | flutter-release | |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | flutter-release | optional; empty means sync stays disabled |

`PLATE_API_TOKEN` is any long random string — it is compared, not verified:

```bash
openssl rand -hex 32
```

### Why the secrets are Lambda environment variables

Unlike ECS, Lambda cannot resolve a Secrets Manager or SSM ARN into an environment variable; doing
that would need either a runtime extension or an AWS SDK dependency inside `server/`, whose `go.mod`
is deliberately stdlib-only. So `OPENROUTER_API_KEY` and `PLATE_API_TOKEN` pass through Terraform as
`sensitive` variables and **land in remote state**. That is the reason the state bucket is private,
versioned, encrypted, and TLS-only. GitHub secrets remain the single source of truth; nothing is
typed into the console.

## Chicken-and-egg on the first deploy

`PLATE_API_URL` does not exist until the server is deployed, and the server is happy without its
key. So:

1. Set the four `AWS_*` secrets and `PLATE_API_TOKEN`. Skip `OPENROUTER_API_KEY` for now.
2. Run **Deploy server** manually. It will fail the smoke test at the `configured: true`
   assertion — that is correct, the key is genuinely missing — but the endpoint is up by then.
3. Read the URL and set it as `PLATE_API_URL`. Easiest from the run's job summary, which prints
   it; locally the app stack's backend is a partial config, so init needs the bucket:
   ```bash
   cd infra/terraform/app
   terraform init -backend-config="bucket=$BUCKET" -backend-config="region=$REGION"
   terraform output -raw function_url
   ```
4. Set `OPENROUTER_API_KEY`, re-run **Deploy server**. Smoke test now passes.
5. Run **Flutter release**.

## Android keystore

Generate once and keep it somewhere you will not lose it — losing it means never being able to
update an installed app again.

```bash
keytool -genkey -v -keystore ~/healthapp-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

base64 -w0 ~/healthapp-upload.jks     # macOS: base64 -i ~/healthapp-upload.jks
```

Paste that into `ANDROID_KEYSTORE_BASE64`. CI writes it to `android/app/upload-keystore.jks` plus
`android/key.properties`, both already covered by `android/.gitignore`.

Locally the keystore is absent, so `android/app/build.gradle.kts` falls back to debug keys and
`flutter run --release` keeps working. The release workflow refuses to run without it rather than
quietly producing a debug-signed artifact that can never be shipped or upgraded.

> The app id changed from the Flutter template `com.example.healthapp` to
> `dev.commrogue.healthapp`, and `MainActivity.kt` moved to match the new `namespace` — the manifest
> resolves `.MainActivity` relative to it. This was free to do now and impossible later: after a
> signed public release, changing the app id makes every install a different app. Shorebird's
> `app_id` lives in `shorebird.yaml` and is unaffected.

---

## Patch or release?

`flutter-release.yml` reads `version:` from `pubspec.yaml`, asks Shorebird whether a release
already exists for it, and takes exactly one path:

- **no release for this version** → `shorebird release android --artifact apk`, which emits both an
  APK (sideloadable, attached to the run) and an AAB (Play upload).
- **release exists** → `shorebird patch android`, delivered over the air.

The paths are never substituted. A failed patch fails the job; it does not fall back to a release,
because that would collide on the version. **The fix for a failed patch is a `pubspec.yaml` version
bump**, then re-run — the job will take the release path on its own.

Two failure modes worth recognising:

- **`database/foods.sqlite` changed.** Shorebird patches Dart code, not assets, so a rebuilt catalog
  cannot reach devices as a patch and the patch fails on the asset diff. This is correct, not a
  problem to work around — `--allow-asset-diffs` is deliberately not passed. Per `CLAUDE.md` a
  replaced catalog also needs a `catalogVersion` bump, so it was always going to be a full release.
- **Native code changed** (a new plugin, an Android manifest edit). Same story: bump and release.

Only the release path uploads artifacts, because only it produces a new installable — a patch leaves
the existing release's APK untouched. When you want a fresh download regardless, bump the version and
run with `mode: release`.

### Flutter version

Pinned to **3.44.6** in both workflows. Shorebird patches are only valid against the Flutter revision
their release was built with, so this is not a knob to float to `stable`. `vercel.json` pins the same
version for the web build; change all three together.

## Rolling back the server

Image tags are git SHAs and ECR tags are immutable, so a rollback is an apply at an older tag:

```bash
cd infra/terraform/app
terraform init -backend-config="bucket=$BUCKET" -backend-config="region=$REGION"
terraform apply -var image_tag=<older-sha> -var lambda_exec_role_arn=<arn>
```

The ECR lifecycle policy keeps the last 10 images. Note that this leaves state pointing at a
commit that is no longer `main` — the next push to `main` rolls forward again.

## Killing the endpoint

The function URL is public — the bearer token is the only gate. To shut it off immediately, set
reserved concurrency to zero; every request then gets a 429:

```bash
aws lambda put-function-concurrency \
  --function-name healthapp-plated --reserved-concurrent-executions 0
```

Or set `-var reserved_concurrency=0` and apply. Reverse it by restoring the default of 5.

## Costs

Lambda bills wall-clock duration, which for this service is mostly time blocked on OpenRouter. At
512 MB and ~8s per detection that is 4 GB-seconds a request, against a perpetual free tier of
400,000 GB-seconds/month — roughly **100,000 detections a month free**, then about **5c per
thousand**. ECR storage is pennies; CloudWatch Logs expire after 14 days.

The alternative, ECS Express Mode (App Runner's successor — App Runner itself went to maintenance
mode on 2026-04-30 and takes no new customers), cannot scale to zero and so bills a shared ALB plus a
Fargate task around the clock, about **$27/month** before any traffic. The crossover is near
**20,000 detections/day**: past that, one long-running container amortises better because it serves
many concurrent I/O-blocked requests while Lambda holds an instance per request.

If you cross it, the swap is contained — drop the `lambda-adapter` COPY from `server/Dockerfile` and
replace `infra/terraform/app/lambda.tf` with an `aws_ecs_express_gateway_service`. Nothing in
`server/` or the Flutter client changes.

## Request size ceiling

Lambda rejects invocations over 6 MB before the handler sees them, which would reach the app as a
bare 413 instead of the server's JSON error envelope. `MAX_REQUEST_BYTES` is therefore set to 5 MiB
so rejection happens inside the server, where it has a documented error code.

This is not a practical limit: `downscaleJpeg` resizes every shot to 1024px @ q80 before upload, so a
full eight-shot plate is around 2 MB of base64. The one path that could exceed it is a photo
`img.decodeImage` cannot parse, which is returned unshrunk — that costs the shot and nothing else,
since `mergePlate` on an empty candidate list is the identity function.
