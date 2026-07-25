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

String _$batchHash() => r'0de917946b652f494e54a802421b41748c4ff2b2';

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
