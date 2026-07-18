// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null when the app runs without `--dart-define` Supabase creds;
/// repositories treat a null client as "remote sync disabled".

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// Null when the app runs without `--dart-define` Supabase creds;
/// repositories treat a null client as "remote sync disabled".

final class SupabaseClientProvider
    extends
        $FunctionalProvider<SupabaseClient?, SupabaseClient?, SupabaseClient?>
    with $Provider<SupabaseClient?> {
  /// Null when the app runs without `--dart-define` Supabase creds;
  /// repositories treat a null client as "remote sync disabled".
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient? create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient?>(value),
    );
  }
}

String _$supabaseClientHash() => r'67a2e2bceb82d0fcfc731bf7493cc2377f29fc04';
