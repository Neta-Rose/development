import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase.g.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Null when the app runs without `--dart-define` Supabase creds;
/// repositories treat a null client as "remote sync disabled".
@Riverpod(keepAlive: true)
SupabaseClient? supabaseClient(Ref ref) =>
    supabaseUrl.isEmpty ? null : Supabase.instance.client;
