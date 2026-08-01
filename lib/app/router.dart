import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/coach/presentation/capture_screen.dart';
import '../features/coach/presentation/coach_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/search/presentation/search_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/search',
          builder: (context, state) => SearchScreen(
            hour: int.tryParse(state.uri.queryParameters['hour'] ?? ''),
          ),
        ),
        GoRoute(path: '/coach', builder: (context, state) => const CoachScreen()),
        GoRoute(
          path: '/coach/capture',
          builder: (context, state) => const CaptureScreen(),
        ),
        // The same search component, in pick mode: it pops with the staged
        // batch instead of writing it to the diary.
        GoRoute(
          path: '/coach/search',
          builder: (context, state) => SearchScreen(
            pickMode: true,
            prefill: state.uri.queryParameters['q'],
          ),
        ),
      ],
    );
