/// Compile-time configuration for the plate-detect service in `server/`.
///
/// Structurally the same as `lib/core/supabase/supabase.dart`: values arrive
/// through `--dart-define`, an empty one means "this feature is off", and that
/// is a normal state rather than an error.
///
/// The OpenRouter key is deliberately *not* here. It lives in the service, which
/// is the whole reason the service exists — a key compiled into the app ships
/// inside the binary and any user can extract it. The model id is not here
/// either: which detector runs is the service's deployment decision, so
/// re-pointing it is an env change and a restart with no client release.
library;

/// Base URL of the plate-detect service, e.g. `https://plated.example.com`.
/// Empty means AI logging is unavailable and the mode is not offered.
const plateApiUrl = String.fromEnvironment('PLATE_API_URL');

/// Shared secret the service requires when it was started with
/// `PLATE_API_TOKEN`. Empty is only correct against a service that is itself
/// running without a token — which is a service anyone who finds it can spend
/// OpenRouter credit on.
///
// ponytail: a build-time shared secret is still extractable from the binary; it
// keeps the *OpenRouter* key off the device and rate-limits casual abuse, and
// that is all it does. The upgrade path is per-user auth on the service, taking
// identity from the Supabase token the app already has a provider for.
const plateApiToken = String.fromEnvironment('PLATE_API_TOKEN');

/// Whether AI logging can run at all.
bool get plateApiConfigured => plateApiUrl.isNotEmpty;

/// The detection endpoint.
Uri get plateDetectEndpoint =>
    Uri.parse('${plateApiUrl.replaceAll(RegExp(r'/+$'), '')}/v1/plate/detect');

/// How long the app waits for one detection.
///
/// The service's own budget is deliberately shorter (24 s by default) and covers
/// its internal resend, so a failure normally arrives described — `timeout`,
/// `unreadable`, `upstream_error` — rather than as this client giving up first.
const plateApiTimeout = Duration(seconds: 30);
