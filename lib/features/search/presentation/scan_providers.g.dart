// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Barcode scan's own state: which product, how many of it, and the torch.
///
/// Nothing staged lives here — the match card writes a `BatchItem` into
/// `batchProvider` like every other mode, so the header totals, the chip strip
/// and the check button need to know nothing about scanning.
///
/// Auto-disposed, which is what cancels the arm timer when the user switches mode
/// or leaves the screen.

@ProviderFor(Scan)
final scanProvider = ScanProvider._();

/// Barcode scan's own state: which product, how many of it, and the torch.
///
/// Nothing staged lives here — the match card writes a `BatchItem` into
/// `batchProvider` like every other mode, so the header totals, the chip strip
/// and the check button need to know nothing about scanning.
///
/// Auto-disposed, which is what cancels the arm timer when the user switches mode
/// or leaves the screen.
final class ScanProvider extends $NotifierProvider<Scan, ScanSession> {
  /// Barcode scan's own state: which product, how many of it, and the torch.
  ///
  /// Nothing staged lives here — the match card writes a `BatchItem` into
  /// `batchProvider` like every other mode, so the header totals, the chip strip
  /// and the check button need to know nothing about scanning.
  ///
  /// Auto-disposed, which is what cancels the arm timer when the user switches mode
  /// or leaves the screen.
  ScanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanHash();

  @$internal
  @override
  Scan create() => Scan();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanSession>(value),
    );
  }
}

String _$scanHash() => r'3a33b79db90fad3b1babb6ec676330ce04d1d75d';

/// Barcode scan's own state: which product, how many of it, and the torch.
///
/// Nothing staged lives here — the match card writes a `BatchItem` into
/// `batchProvider` like every other mode, so the header totals, the chip strip
/// and the check button need to know nothing about scanning.
///
/// Auto-disposed, which is what cancels the arm timer when the user switches mode
/// or leaves the screen.

abstract class _$Scan extends $Notifier<ScanSession> {
  ScanSession build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScanSession, ScanSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScanSession, ScanSession>,
              ScanSession,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
