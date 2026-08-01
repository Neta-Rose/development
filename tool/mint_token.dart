// Prints a Cloud Run identity token for Postman. Dev-time only.
import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

const url = 'https://food-suggest-engine-370210859891.us-central1.run.app';
const keyPath =
    r'C:\Users\netaz\Desktop\Projects\other\food-app\secrets\app-caller-key.json';

Future<void> main() async {
  final k = jsonDecode(await File(keyPath).readAsString()) as Map<String, dynamic>;
  final now = DateTime.now();
  final a = JWT({
    'iss': k['client_email'],
    'aud': k['token_uri'],
    'target_audience': url,
    'iat': now.millisecondsSinceEpoch ~/ 1000,
    'exp': now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
  }).sign(RSAPrivateKey(k['private_key'] as String), algorithm: JWTAlgorithm.RS256);
  final r = await http.post(Uri.parse(k['token_uri'] as String), body: {
    'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    'assertion': a,
  });
  stdout.writeln((jsonDecode(r.body) as Map<String, dynamic>)['id_token']);
}
