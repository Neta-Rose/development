// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachRepository)
final coachRepositoryProvider = CoachRepositoryProvider._();

final class CoachRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<CoachRepository>,
          CoachRepository,
          FutureOr<CoachRepository>
        >
    with $FutureModifier<CoachRepository>, $FutureProvider<CoachRepository> {
  CoachRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<CoachRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CoachRepository> create(Ref ref) {
    return coachRepository(ref);
  }
}

String _$coachRepositoryHash() => r'79cf6911446c759a74b5d2ee8029cfc6e8da6691';
