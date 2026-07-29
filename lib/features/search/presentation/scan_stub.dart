import '../../home/data/catalog_repository.dart';
import 'scan_providers.dart';

/// The products barcode scan resolves to, in order.
///
// ponytail: nothing here reads a barcode. Scan mode cycles this fixed list on a
// timer, so the interface can be built and used before decoding exists. Ceiling:
// four products, always the same four, in the same order, and the codes are
// invented. Upgrade path: delete this file — `Scan.rescan` resolves the decoded
// symbol against a `gtin_upc` column in the catalog instead, and nothing in
// `scan_pane.dart` changes.
final scanProducts = [
  _product(
    brand: 'Torrent Nutrition',
    code: '8 412755 093021',
    name: 'Whey Isolate, Vanilla',
    emoji: '🥤',
    serving: 'scoop',
    servingG: 30,
    kcal: 120,
    protein: 27,
    carbs: 2,
    fat: 1,
  ),
  _product(
    brand: 'Northfield Dairy',
    code: '7 290011 664312',
    name: 'Greek Yogurt 2%',
    emoji: '🥣',
    serving: 'pot',
    servingG: 170,
    kcal: 100,
    protein: 17,
    carbs: 6,
    fat: 3,
  ),
  _product(
    brand: 'Mill & Ash Bakery',
    code: '5 060337 502733',
    name: 'Sourdough Loaf',
    emoji: '🍞',
    serving: 'slice',
    servingG: 50,
    kcal: 120,
    protein: 4,
    carbs: 24,
    fat: 1,
  ),
  _product(
    brand: 'Casa Verde',
    code: '0 041331 023117',
    name: 'Black Beans, No Salt',
    emoji: '🫘',
    serving: 'can',
    servingG: 240,
    kcal: 190,
    protein: 12,
    carbs: 34,
    fat: 1,
  ),
];

/// A label's numbers are per serving; every nutrient in this app is per 100 g.
/// Converted once here, so `Portion.scale` converts back and the card shows the
/// number the packet does.
///
/// `isCustom` with neither id is the same shape quick add produces — a food with
/// no row yet, which `Batch.logAll` writes on its way out.
ScanProduct _product({
  required String brand,
  required String code,
  required String name,
  required String emoji,
  required String serving,
  required double servingG,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
}) {
  double per100g(double perServing) => perServing * 100 / servingG;
  return ScanProduct(
    brand: brand,
    code: code,
    food: FoodHit(
      name: name,
      isCustom: true,
      emoji: emoji,
      servingG: servingG,
      servingLabel: serving,
      kcal100g: per100g(kcal),
      protein100g: per100g(protein),
      carb100g: per100g(carbs),
      fat100g: per100g(fat),
    ),
  );
}
