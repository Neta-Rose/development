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

String _$dailySummaryHash() => r'7652ff96e35a741e85f4eead7023368ceb8a65ca';

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

String _$timelineHash() => r'207cc632b1c3c86c1ab1f71d405f0f1040b91183';
