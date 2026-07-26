// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'd7661c7cd48d895c1983ea94c0c4b94ff6c761a8';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Hits for the current query — or, with the box empty, what was logged
/// recently. Both arrive as [FoodHit], so the list has one row type.

@ProviderFor(searchResults)
final searchResultsProvider = SearchResultsProvider._();

/// Hits for the current query — or, with the box empty, what was logged
/// recently. Both arrive as [FoodHit], so the list has one row type.

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FoodHit>>,
          List<FoodHit>,
          FutureOr<List<FoodHit>>
        >
    with $FutureModifier<List<FoodHit>>, $FutureProvider<List<FoodHit>> {
  /// Hits for the current query — or, with the box empty, what was logged
  /// recently. Both arrive as [FoodHit], so the list has one row type.
  SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<FoodHit>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FoodHit>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'fc7c42a22ee7bab077293a77e937f08a940bc607';

/// The measures a catalog food comes in, for the portion pad's unit chips.
/// Catalog-only: custom foods keep their single serving label.

@ProviderFor(foodPortions)
final foodPortionsProvider = FoodPortionsFamily._();

/// The measures a catalog food comes in, for the portion pad's unit chips.
/// Catalog-only: custom foods keep their single serving label.

final class FoodPortionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({double gramWeight, String label})>>,
          List<({double gramWeight, String label})>,
          FutureOr<List<({double gramWeight, String label})>>
        >
    with
        $FutureModifier<List<({double gramWeight, String label})>>,
        $FutureProvider<List<({double gramWeight, String label})>> {
  /// The measures a catalog food comes in, for the portion pad's unit chips.
  /// Catalog-only: custom foods keep their single serving label.
  FoodPortionsProvider._({
    required FoodPortionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'foodPortionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodPortionsHash();

  @override
  String toString() {
    return r'foodPortionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<({double gramWeight, String label})>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<({double gramWeight, String label})>> create(Ref ref) {
    final argument = this.argument as int;
    return foodPortions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FoodPortionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodPortionsHash() => r'7547a41a52df8a006ef134d85925084c3feb2766';

/// The measures a catalog food comes in, for the portion pad's unit chips.
/// Catalog-only: custom foods keep their single serving label.

final class FoodPortionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<({double gramWeight, String label})>>,
          int
        > {
  FoodPortionsFamily._()
    : super(
        retry: null,
        name: r'foodPortionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The measures a catalog food comes in, for the portion pad's unit chips.
  /// Catalog-only: custom foods keep their single serving label.

  FoodPortionsProvider call(int foodId) =>
      FoodPortionsProvider._(argument: foodId, from: this);

  @override
  String toString() => r'foodPortionsProvider';
}

/// The detail screen's fibre/sugar/sat-fat/sodium, per 100 g. Keyed on the ids
/// rather than the [FoodHit] itself, which has no value equality.

@ProviderFor(foodExtras)
final foodExtrasProvider = FoodExtrasFamily._();

/// The detail screen's fibre/sugar/sat-fat/sodium, per 100 g. Keyed on the ids
/// rather than the [FoodHit] itself, which has no value equality.

final class FoodExtrasProvider
    extends
        $FunctionalProvider<
          AsyncValue<FoodExtras?>,
          FoodExtras?,
          FutureOr<FoodExtras?>
        >
    with $FutureModifier<FoodExtras?>, $FutureProvider<FoodExtras?> {
  /// The detail screen's fibre/sugar/sat-fat/sodium, per 100 g. Keyed on the ids
  /// rather than the [FoodHit] itself, which has no value equality.
  FoodExtrasProvider._({
    required FoodExtrasFamily super.from,
    required ({int? foodId, String? customId}) super.argument,
  }) : super(
         retry: null,
         name: r'foodExtrasProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodExtrasHash();

  @override
  String toString() {
    return r'foodExtrasProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FoodExtras?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FoodExtras?> create(Ref ref) {
    final argument = this.argument as ({int? foodId, String? customId});
    return foodExtras(
      ref,
      foodId: argument.foodId,
      customId: argument.customId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoodExtrasProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodExtrasHash() => r'cf4cc3c2f489eda976b73692c379857c7159a3f4';

/// The detail screen's fibre/sugar/sat-fat/sodium, per 100 g. Keyed on the ids
/// rather than the [FoodHit] itself, which has no value equality.

final class FoodExtrasFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<FoodExtras?>,
          ({int? foodId, String? customId})
        > {
  FoodExtrasFamily._()
    : super(
        retry: null,
        name: r'foodExtrasProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The detail screen's fibre/sugar/sat-fat/sodium, per 100 g. Keyed on the ids
  /// rather than the [FoodHit] itself, which has no value equality.

  FoodExtrasProvider call({int? foodId, String? customId}) =>
      FoodExtrasProvider._(
        argument: (foodId: foodId, customId: customId),
        from: this,
      );

  @override
  String toString() => r'foodExtrasProvider';
}

/// Foods staged on this screen. Nothing is written until [Batch.logAll]; the
/// batch is screen-scoped, so leaving throws it away.

@ProviderFor(Batch)
final batchProvider = BatchProvider._();

/// Foods staged on this screen. Nothing is written until [Batch.logAll]; the
/// batch is screen-scoped, so leaving throws it away.
final class BatchProvider extends $NotifierProvider<Batch, List<BatchItem>> {
  /// Foods staged on this screen. Nothing is written until [Batch.logAll]; the
  /// batch is screen-scoped, so leaving throws it away.
  BatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchHash();

  @$internal
  @override
  Batch create() => Batch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BatchItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BatchItem>>(value),
    );
  }
}

String _$batchHash() => r'fdba5848276356f21f66ec9298604ae77d4f48b0';

/// Foods staged on this screen. Nothing is written until [Batch.logAll]; the
/// batch is screen-scoped, so leaving throws it away.

abstract class _$Batch extends $Notifier<List<BatchItem>> {
  List<BatchItem> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<BatchItem>, List<BatchItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BatchItem>, List<BatchItem>>,
              List<BatchItem>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
