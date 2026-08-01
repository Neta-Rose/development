// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(detectionSource)
final detectionSourceProvider = DetectionSourceProvider._();

final class DetectionSourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<DetectionSource>,
          DetectionSource,
          FutureOr<DetectionSource>
        >
    with $FutureModifier<DetectionSource>, $FutureProvider<DetectionSource> {
  DetectionSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detectionSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detectionSourceHash();

  @$internal
  @override
  $FutureProviderElement<DetectionSource> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DetectionSource> create(Ref ref) {
    return detectionSource(ref);
  }
}

String _$detectionSourceHash() => r'dd945e0c456d24673e088002b22430272b1171cc';
