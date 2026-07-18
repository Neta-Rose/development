import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/supabase/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      // Legacy anon JWT keys still work; switch to publishableKey when the
      // project migrates to new API keys.
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }
  runApp(const ProviderScope(child: App()));
}
