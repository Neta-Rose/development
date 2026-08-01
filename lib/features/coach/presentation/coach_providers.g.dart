// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachContext)
final coachContextProvider = CoachContextProvider._();

final class CoachContextProvider
    extends $FunctionalProvider<CoachContext, CoachContext, CoachContext>
    with $Provider<CoachContext> {
  CoachContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachContextHash();

  @$internal
  @override
  $ProviderElement<CoachContext> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachContext create(Ref ref) {
    return coachContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachContext value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachContext>(value),
    );
  }
}

String _$coachContextHash() => r'8ca08172e31b05ecbf2a7e61818fb3d03519cf8f';

/// Which candidate universe the run draws on. Only [CoachMode.onTheTable] is
/// wired; "cook something" builds the toggle but has no server-side source yet.

@ProviderFor(Mode)
final modeProvider = ModeProvider._();

/// Which candidate universe the run draws on. Only [CoachMode.onTheTable] is
/// wired; "cook something" builds the toggle but has no server-side source yet.
final class ModeProvider extends $NotifierProvider<Mode, CoachMode> {
  /// Which candidate universe the run draws on. Only [CoachMode.onTheTable] is
  /// wired; "cook something" builds the toggle but has no server-side source yet.
  ModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modeHash();

  @$internal
  @override
  Mode create() => Mode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachMode>(value),
    );
  }
}

String _$modeHash() => r'c343f69a21417500a6c5533bd4e1357571da4901';

/// Which candidate universe the run draws on. Only [CoachMode.onTheTable] is
/// wired; "cook something" builds the toggle but has no server-side source yet.

abstract class _$Mode extends $Notifier<CoachMode> {
  CoachMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoachMode, CoachMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoachMode, CoachMode>,
              CoachMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The capture tray. Survives navigation between the coach and capture screens,
/// which is why it is not screen-scoped.

@ProviderFor(Tray)
final trayProvider = TrayProvider._();

/// The capture tray. Survives navigation between the coach and capture screens,
/// which is why it is not screen-scoped.
final class TrayProvider extends $NotifierProvider<Tray, List<Candidate>> {
  /// The capture tray. Survives navigation between the coach and capture screens,
  /// which is why it is not screen-scoped.
  TrayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trayHash();

  @$internal
  @override
  Tray create() => Tray();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Candidate> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Candidate>>(value),
    );
  }
}

String _$trayHash() => r'a6a20e1463b5401dc89c54cae80dcf7da678f52f';

/// The capture tray. Survives navigation between the coach and capture screens,
/// which is why it is not screen-scoped.

abstract class _$Tray extends $Notifier<List<Candidate>> {
  List<Candidate> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Candidate>, List<Candidate>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Candidate>, List<Candidate>>,
              List<Candidate>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which suggestion is expanded. Rank 1 by default, only one at a time, and -1
/// for none. Separate from [CoachRun] so expanding a row cannot disturb the
/// results it is expanding.

@ProviderFor(ExpandedRank)
final expandedRankProvider = ExpandedRankProvider._();

/// Which suggestion is expanded. Rank 1 by default, only one at a time, and -1
/// for none. Separate from [CoachRun] so expanding a row cannot disturb the
/// results it is expanding.
final class ExpandedRankProvider extends $NotifierProvider<ExpandedRank, int> {
  /// Which suggestion is expanded. Rank 1 by default, only one at a time, and -1
  /// for none. Separate from [CoachRun] so expanding a row cannot disturb the
  /// results it is expanding.
  ExpandedRankProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expandedRankProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expandedRankHash();

  @$internal
  @override
  ExpandedRank create() => ExpandedRank();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$expandedRankHash() => r'd839b412170fe68ecab4d51e6096d7eb719996e6';

/// Which suggestion is expanded. Rank 1 by default, only one at a time, and -1
/// for none. Separate from [CoachRun] so expanding a row cannot disturb the
/// results it is expanding.

abstract class _$ExpandedRank extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CoachRun)
final coachRunProvider = CoachRunProvider._();

final class CoachRunProvider extends $NotifierProvider<CoachRun, CoachState> {
  CoachRunProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachRunProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachRunHash();

  @$internal
  @override
  CoachRun create() => CoachRun();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachState>(value),
    );
  }
}

String _$coachRunHash() => r'8340c675071ecad8c35cef47f91f429d1670c21a';

abstract class _$CoachRun extends $Notifier<CoachState> {
  CoachState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoachState, CoachState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoachState, CoachState>,
              CoachState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
