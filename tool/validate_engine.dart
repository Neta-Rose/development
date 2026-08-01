// Dev-time validation of the food suggestion engine contract.
//
// Proves, in Dart rather than curl, the exact path the app will take:
//   service-account key -> RS256 assertion -> Google identity token
//   -> authenticated POST /v1/suggest with a real user_state.
//
// Run from the repo root:
//   dart run tool/validate_engine.dart
//
// Not shipped: `tool/` is outside `lib/`, so nothing here reaches the app.
import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

const engineUrl =
    'https://food-suggest-engine-370210859891.us-central1.run.app';
const keyPath =
    r'C:\Users\netaz\Desktop\Projects\other\food-app\secrets\app-caller-key.json';

/// Exchanges the service-account key for an identity token scoped to
/// [audience]. Cloud Run authenticates with an *identity* token, not an OAuth
/// access token, which is why this is the jwt-bearer flow with a
/// `target_audience` claim rather than a plain scope request.
Future<String> mintIdToken(Map<String, dynamic> key, String audience) async {
  final now = DateTime.now();
  final jwt = JWT(
    {
      'iss': key['client_email'],
      'aud': key['token_uri'],
      'target_audience': audience,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
    },
  );
  final assertion = jwt.sign(
    RSAPrivateKey(key['private_key'] as String),
    algorithm: JWTAlgorithm.RS256,
  );

  final res = await http.post(
    Uri.parse(key['token_uri'] as String),
    body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': assertion,
    },
  );
  if (res.statusCode != 200) {
    throw Exception('token exchange ${res.statusCode}: ${res.body}');
  }
  return (jsonDecode(res.body) as Map<String, dynamic>)['id_token'] as String;
}

Future<(int, Map<String, dynamic>)> suggest(
    String token, Map<String, dynamic> body) async {
  final res = await http.post(
    Uri.parse('$engineUrl/v1/suggest'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );
  return (res.statusCode, jsonDecode(res.body) as Map<String, dynamic>);
}

/// Two real catalog foods, already verified to exist in `database/foods.sqlite`
/// with these exact per-100 g values. Hardcoded here only so this script stays
/// standalone — the app reads them live from the attached catalog.
final _candidates = [
  {
    'name': 'grilled chicken breast',
    'food_id': 'fdc_171534',
    'confidence': 0.91,
    'amount_hint_g': 180,
    'food': {
      'food_id': 171534,
      'display_name': 'Grilled chicken breast',
      'category': 'Poultry Products',
      'serving_g': 140,
      'nutrition': {
        'energy_kcal': 151.0,
        'protein_g': 30.54,
        'carb_g': 0.0,
        'fat_g': 3.17,
        'fiber_g': 0.0,
        'sugar_g': 0.0,
        'sat_fat_g': 0.88,
        'sodium_mg': 52.0,
      },
    },
  },
  {
    'name': 'white rice',
    'food_id': 'fdc_2708403',
    'confidence': 0.88,
    'amount_hint_g': 200,
    'food': {
      'food_id': 2708403,
      'display_name': 'White rice',
      'category': 'Rice',
      'serving_g': 150,
      'nutrition': {
        'energy_kcal': 129.0,
        'protein_g': 2.67,
        'carb_g': 28.2,
        'fat_g': 0.28,
        'fiber_g': 0.9,
        'sugar_g': 0.05,
        'sat_fat_g': 0.08,
        'sodium_mg': 1.0,
      },
    },
  },
];

/// Mirrors what the app will compute from `log_entries`: targets minus what is
/// actually logged today.
final _userState = {
  'remaining_today': {
    'kcal': 1240,
    'protein_g': 68,
    'carbs_g': 120,
    'fat_g': 32,
  },
  'remaining_meals': 2,
  'preferences': {
    'diets': ['kosher'],
    'allergies': ['shellfish'],
  },
  'workouts': [
    {
      'type': 'resistance',
      'ended_at': '2026-07-26T15:42:00Z',
      'duration_min': 60,
      'intensity': 'high',
    }
  ],
};

Future<void> main() async {
  final key = jsonDecode(await File(keyPath).readAsString())
      as Map<String, dynamic>;
  stdout.writeln('key: ${key['client_email']}');

  // 1. Unauthenticated must be rejected.
  final anon = await http.post(
    Uri.parse('$engineUrl/v1/suggest'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'intent': 'browse'}),
  );
  stdout.writeln('\n[1] unauthenticated       -> HTTP ${anon.statusCode} '
      '${anon.statusCode == 403 ? "(rejected, as expected)" : "UNEXPECTED"}');

  final token = await mintIdToken(key, engineUrl);
  stdout.writeln('[2] identity token minted -> ${token.length} chars, '
      'aud=$engineUrl');

  // 3. Authenticated but no user_state must 422 with an explanation.
  var (code, body) = await suggest(token, {
    'intent': 'pick_from_available',
    'no_db': true,
    'candidate_set': {'source': 'photo_extraction', 'items': _candidates},
  });
  stdout.writeln('[3] no user_state         -> HTTP $code  ${body['error']}');

  // 4. The real call.
  (code, body) = await suggest(token, {
    'intent': 'pick_from_available',
    'meal_slot': 'dinner',
    'no_db': true,
    'explain_level': 'full',
    'n_suggestions': 3,
    'user_state': _userState,
    'candidate_set': {'source': 'photo_extraction', 'items': _candidates},
  });
  stdout.writeln('\n[4] full request          -> HTTP $code  '
      'total=${body['timing_ms']?['total']}ms  degraded=${body['degraded']}');
  stdout.writeln('    rulebook=${body['rulebook_version']}  '
      'ctx=${body['context_snapshot_id']}');
  stdout.writeln('    excluded_summary=${jsonEncode(body['excluded_summary'])}');

  for (final s in (body['suggestions'] as List? ?? [])) {
    final n = s['nutrients'];
    stdout.writeln('\n  #${s['rank']} score=${s['total_score']} '
        '-> ${((s['total_score'] as num) * 100).round()}'
        '  ${n['kcal']}kcal ${n['protein_g']}P ${n['carbs_g']}C ${n['fat_g']}F');
    stdout.writeln('     ${(s['items'] as List).map((i) =>
        "${i['name']} ${i['amount']['value']}${i['amount']['unit']}").join(' + ')}');
    final bd = s['breakdown'] as List;
    final maxW = bd.fold<double>(
        0, (a, b) => (b['weighted'] as num) > a ? (b['weighted'] as num).toDouble() : a);
    for (final b in bd) {
      final weak = (b['weighted'] as num) < 0.4 * maxW;
      stdout.writeln('     ${b['signal'].toString().padRight(22)} '
          'raw=${b['raw']} wtd=${b['weighted']} ${weak ? "weak  " : "STRONG"} '
          '| ${b['explain']}');
    }
  }

  // 5. Deterministic empty result, per the engine owner's instruction.
  (code, body) = await suggest(token, {
    'intent': 'browse',
    'meal_slot': 'dinner',
    'user_state': _userState,
    'constraints': [
      {'field': 'attributes.prep_minutes', 'op': 'lte', 'value': 0}
    ],
  });
  stdout.writeln('\n[5] over-constrained browse -> HTTP $code  '
      'suggestions=${(body['suggestions'] as List?)?.length}  '
      'degraded=${body['degraded']} reason=${body['degraded_reason']}');
  stdout.writeln('    excluded_summary=${jsonEncode(body['excluded_summary'])}');
}
