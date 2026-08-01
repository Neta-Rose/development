/// A food chosen on the search screen and handed back to whoever opened it.
///
/// The search screen has two commit modes: its default writes the staged batch
/// straight to the diary, and pick mode pops with this instead. That is the
/// whole adapter — the rows, the swipe-to-portion gesture and the batch tray
/// are the same component either way.
class PickedFood {
  const PickedFood({
    required this.name,
    required this.grams,
    this.foodId,
    this.customFoodId,
  });

  final String name;

  /// Grams the user actually picked, via tap or the portion swipe.
  final double grams;

  /// Exactly one of these is set, matching `log_entries`' own CHECK.
  final int? foodId;
  final String? customFoodId;
}
