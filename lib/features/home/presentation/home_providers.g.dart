// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(now)
final nowProvider = NowProvider._();

final class NowProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$nowHash() => r'cd84bcb298b7b9e78457b899f2d2445afe8d297f';

@ProviderFor(todayEntries)
final todayEntriesProvider = TodayEntriesProvider._();

final class TodayEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FoodEntry>>,
          List<FoodEntry>,
          Stream<List<FoodEntry>>
        >
    with $FutureModifier<List<FoodEntry>>, $StreamProvider<List<FoodEntry>> {
  TodayEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<FoodEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FoodEntry>> create(Ref ref) {
    return todayEntries(ref);
  }
}

String _$todayEntriesHash() => r'c775c324124df50a91d779208f4e54bf469af17e';

@ProviderFor(dailySummary)
final dailySummaryProvider = DailySummaryProvider._();

final class DailySummaryProvider
    extends $FunctionalProvider<DailySummary, DailySummary, DailySummary>
    with $Provider<DailySummary> {
  DailySummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailySummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailySummaryHash();

  @$internal
  @override
  $ProviderElement<DailySummary> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DailySummary create(Ref ref) {
    return dailySummary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailySummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailySummary>(value),
    );
  }
}

String _$dailySummaryHash() => r'4fc424f0248c2f2029ff8b9e468219b09ba08446';

@ProviderFor(anabolicWindow)
final anabolicWindowProvider = AnabolicWindowProvider._();

final class AnabolicWindowProvider
    extends
        $FunctionalProvider<AnabolicWindow?, AnabolicWindow?, AnabolicWindow?>
    with $Provider<AnabolicWindow?> {
  AnabolicWindowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'anabolicWindowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$anabolicWindowHash();

  @$internal
  @override
  $ProviderElement<AnabolicWindow?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnabolicWindow? create(Ref ref) {
    return anabolicWindow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnabolicWindow? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnabolicWindow?>(value),
    );
  }
}

String _$anabolicWindowHash() => r'021554d8a9b3de8ebaf044839469660bd8064eca';

@ProviderFor(timeline)
final timelineProvider = TimelineProvider._();

final class TimelineProvider
    extends
        $FunctionalProvider<
          List<TimelineHour>,
          List<TimelineHour>,
          List<TimelineHour>
        >
    with $Provider<List<TimelineHour>> {
  TimelineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'timelineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$timelineHash();

  @$internal
  @override
  $ProviderElement<List<TimelineHour>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TimelineHour> create(Ref ref) {
    return timeline(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TimelineHour> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TimelineHour>>(value),
    );
  }
}

String _$timelineHash() => r'de5529b01b40cde2b9cdcc9baf42785d2e6a8d7e';
