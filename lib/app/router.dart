import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      ],
    );
