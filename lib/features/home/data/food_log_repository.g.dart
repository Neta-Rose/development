// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_log_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foodLogRepository)
final foodLogRepositoryProvider = FoodLogRepositoryProvider._();

final class FoodLogRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FoodLogRepository>,
          FoodLogRepository,
          FutureOr<FoodLogRepository>
        >
    with
        $FutureModifier<FoodLogRepository>,
        $FutureProvider<FoodLogRepository> {
  FoodLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodLogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodLogRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<FoodLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FoodLogRepository> create(Ref ref) {
    return foodLogRepository(ref);
  }
}

String _$foodLogRepositoryHash() => r'eca0babdfc68c0beaabbf043a363b8be1d76b0f8';
