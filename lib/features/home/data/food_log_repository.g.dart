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
          FoodLogRepository,
          FoodLogRepository,
          FoodLogRepository
        >
    with $Provider<FoodLogRepository> {
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
  $ProviderElement<FoodLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FoodLogRepository create(Ref ref) {
    return foodLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FoodLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FoodLogRepository>(value),
    );
  }
}

String _$foodLogRepositoryHash() => r'd4e3fa7591cf38fc5922babeb2a944ab50325e79';
