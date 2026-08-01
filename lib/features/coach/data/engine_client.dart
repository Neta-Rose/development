/// HTTP client for the food suggestion engine.
///
/// ⚠️ SECURITY — TEMPORARY, PRE-PUBLIC ONLY ⚠️
/// The engine sits behind Cloud Run IAM and needs a Google identity token
/// minted from a *service-account key*. That key is a password. This file
/// currently mints the token **on the device**, which means the key ships
/// inside the client bundle — recoverable from an APK with `unzip`, and served
/// in plain sight by the web build.
///
/// This is a deliberate, temporary decision to unblock a pre-public build.
/// Before any public release:
///   1. revoke this key in IAM and issue a new one,
///   2. stand up a server-side proxy holding it (the repo already deploys to
///      Vercel, so `/api/suggest` is the natural home),
///   3. point [EngineClient.baseUrl] at that proxy and delete [_ServiceAccount]
///      and the key asset entirely.
///
/// Everything outside this file is already proxy-ready: the rest of the app
/// talks to `CoachRepository` and never sees a credential.
library;

import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../domain/suggest.dart';

/// Thrown for anything the UI should surface as a failed run.
class EngineException implements Exception {
  const EngineException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => message;
}

class _ServiceAccount {
  const _ServiceAccount(this.clientEmail, this.privateKey, this.tokenUri);

  factory _ServiceAccount.fromJson(Map<String, dynamic> j) => _ServiceAccount(
        j['client_email'] as String,
        j['private_key'] as String,
        j['token_uri'] as String,
      );

  final String clientEmail, privateKey, tokenUri;
}

class EngineClient {
  EngineClient({http.Client? http_}) : _http = http_ ?? http.Client();

  final http.Client _http;

  /// Swap this for the proxy origin when one exists; nothing else changes.
  static const baseUrl =
      'https://food-suggest-engine-370210859891.us-central1.run.app';

  /// Bundled key. Gitignored, and loaded as an asset rather than compiled in so
  /// deleting it is enough to break the build loudly rather than silently ship
  /// a stale credential.
  static const _keyAsset = 'secrets/app-caller-key.json';

  _ServiceAccount? _account;
  String? _token;
  DateTime? _tokenExpiry;

  Future<_ServiceAccount> _loadAccount() async {
    if (_account != null) return _account!;
    try {
      final raw = await rootBundle.loadString(_keyAsset);
      return _account = _ServiceAccount.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const EngineException(
          'Coach credentials are missing from this build.');
    }
  }

  /// Cloud Run authenticates with an *identity* token, not an OAuth access
  /// token — hence the jwt-bearer flow with a `target_audience` claim rather
  /// than a scope request. Tokens last an hour; this refreshes a minute early.
  Future<String> _idToken() async {
    final cached = _token;
    if (cached != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return cached;
    }
    final acct = await _loadAccount();
    final now = DateTime.now();
    final assertion = JWT({
      'iss': acct.clientEmail,
      'aud': acct.tokenUri,
      'target_audience': baseUrl,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
    }).sign(RSAPrivateKey(acct.privateKey), algorithm: JWTAlgorithm.RS256);

    final res = await _http.post(Uri.parse(acct.tokenUri), body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': assertion,
    });
    if (res.statusCode != 200) {
      throw EngineException('Could not authenticate with the coach service.',
          status: res.statusCode);
    }
    _tokenExpiry = now.add(const Duration(minutes: 50));
    return _token =
        (jsonDecode(res.body) as Map<String, dynamic>)['id_token'] as String;
  }

  Future<SuggestResponse> suggest(SuggestRequest request) async {
    final token = await _idToken();
    final res = await _http.post(
      Uri.parse('$baseUrl/v1/suggest'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (res.statusCode != 200) {
      // The engine reports its own reasons well; surface them rather than a
      // raw exception string, but never a bare status code alone.
      String detail;
      try {
        detail = (jsonDecode(res.body) as Map<String, dynamic>)['error']
                as String? ??
            res.body;
      } catch (_) {
        detail = 'HTTP ${res.statusCode}';
      }
      throw EngineException(detail, status: res.statusCode);
    }
    return SuggestResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
}
