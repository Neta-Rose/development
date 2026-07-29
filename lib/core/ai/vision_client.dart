import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'plate_api_config.dart';
import 'vision_models.dart';

/// One item already staged on the plate, sent so the detector reuses its id
/// rather than minting a new one for food it has already been shown. Without
/// this, a second shot of the same chicken thigh comes back as a second thigh.
typedef PlateSummary = ({String instanceId, String name, double grams});

/// Either a plate or a reason there isn't one.
typedef VisionResult = ({VisionReply? reply, VisionFailure? failure});

/// The detection port. An interface rather than a concrete class so every test
/// above this line — merging, matching, writing, widgets — runs with no network
/// and no credentials.
abstract interface class VisionClient {
  /// Detects the foods in [shots], which are JPEG bytes in shot order, shot 1
  /// first.
  ///
  /// The **whole batch** goes on every call, not just the newest shot. That is
  /// the design, not an oversight: deduplication is the detector's job, and a
  /// detector shown one photo at a time cannot tell "the same chicken thigh
  /// again" from "a second chicken thigh".
  Future<VisionResult> detect({
    required List<Uint8List> shots,
    required List<PlateSummary> plate,
  });
}

/// Talks to the Go plate-detect service in `server/`.
///
/// Thin on purpose. The service owns the OpenRouter key, the model id, the
/// prompt, the response schema, the resend on an unreadable reply and the
/// deduplication safety net; this end owns the transport and the failure
/// mapping, and nothing else.
class PlateApiVisionClient implements VisionClient {
  PlateApiVisionClient(this._http);

  final http.Client _http;

  @override
  Future<VisionResult> detect({
    required List<Uint8List> shots,
    required List<PlateSummary> plate,
  }) async {
    // Checked before a request is built, so a programming error cannot send an
    // unaddressed call.
    if (!plateApiConfigured) {
      return (reply: null, failure: const VisionNotConfigured());
    }
    if (shots.isEmpty) {
      return (reply: null, failure: const VisionNoFood());
    }

    final body = jsonEncode({
      'shots': [for (final shot in shots) base64Encode(shot)],
      'plate': [
        for (final item in plate)
          {
            'instance_id': item.instanceId,
            'name': item.name,
            'grams': item.grams,
          },
      ],
    });

    http.Response response;
    try {
      response = await _http
          .post(
            plateDetectEndpoint,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              if (plateApiToken.isNotEmpty)
                'Authorization': 'Bearer $plateApiToken',
            },
            body: body,
          )
          .timeout(plateApiTimeout);
    } on TimeoutException {
      return (reply: null, failure: const VisionTimeout());
    } on http.ClientException {
      // package:http funnels SocketException and HandshakeException through
      // this, on io and on web alike — which is why nothing here imports
      // dart:io. `lib/core/database/connection/` stays the only
      // platform-branching code in lib/.
      return (reply: null, failure: const VisionNoConnection());
    } on Exception {
      // Anything else thrown by the send path is a transport problem as far as
      // the user is concerned. Swallowed rather than rethrown because the
      // alternative is an unhandled error tearing down the capture session and
      // taking the plate the user already built with it.
      return (reply: null, failure: const VisionNoConnection());
    }

    if (response.statusCode != 200) {
      return (reply: null, failure: _failureFor(response));
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return _unreadable;
      return (reply: VisionReply.fromJson(decoded), failure: null);
    } on FormatException {
      return _unreadable;
    } on TypeError {
      // A field of the wrong JSON type reaches here rather than as a
      // FormatException.
      return _unreadable;
    }
  }

  static const VisionResult _unreadable =
      (reply: null, failure: VisionUnreadable());

  /// Maps an error response onto a failure.
  ///
  /// The service's `error.code` decides, not the HTTP status: several distinct
  /// failures share 502 and each one gets different copy. The status is only the
  /// fallback for a response that is not one of ours at all — a proxy's 504, a
  /// load balancer's 502.
  VisionFailure _failureFor(http.Response response) {
    final code = _errorCode(response.body);
    switch (code?.code) {
      case 'not_configured':
        return const VisionNotConfigured();
      case 'no_connection':
        return const VisionNoConnection();
      case 'timeout':
        return const VisionTimeout();
      case 'unreadable':
        return const VisionUnreadable();
      case 'upstream_error':
        // The model provider's own status, so the pane can name it.
        return VisionHttpError(
            code!.upstreamStatus != 0 ? code.upstreamStatus : response.statusCode);
    }
    if (response.statusCode == 504) return const VisionTimeout();
    if (response.statusCode == 503) return const VisionNotConfigured();
    return VisionHttpError(response.statusCode);
  }

  ({String code, int upstreamStatus})? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final error = decoded['error'];
      if (error is! Map) return null;
      final code = error['code'];
      if (code is! String) return null;
      final status = error['status'];
      return (code: code, upstreamStatus: status is int ? status : 0);
    } on FormatException {
      // Not our error shape — an HTML error page from something in between.
      return null;
    }
  }
}
