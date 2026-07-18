import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio.g.dart';

/// HTTP client for non-Supabase APIs (e.g. future food-database search).
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  if (kDebugMode) {
    client.interceptors.add(LogInterceptor(responseBody: false));
  }
  return client;
}
