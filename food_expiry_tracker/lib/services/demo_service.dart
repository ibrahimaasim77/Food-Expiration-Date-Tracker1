import '../models/food_item.dart';
import '../services/database_service.dart';

class DemoService {
  static List<FoodItem> _buildItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      // ── Expired (red) ───────────────────────────────────────────
      FoodItem(
        name: 'Chicken Breast',
        category: 'Meat',
        expiryDate: today.subtract(const Duration(days: 1)),
        safeDaysAfterExpiry: 1,
      ),
      FoodItem(
        name: 'Orange Juice',
        category: 'Beverages',
        expiryDate: today.subtract(const Duration(days: 3)),
        safeDaysAfterExpiry: 7,
      ),

      // ── Expiring very soon ≤ 1 day (orange) ────────────────────
      FoodItem(
        name: 'Salmon Fillet',
        category: 'Seafood',
        expiryDate: today.add(const Duration(days: 1)),
        safeDaysAfterExpiry: 1,
      ),
      FoodItem(
        name: 'Sourdough Bread',
        category: 'Bakery',
        expiryDate: today.add(const Duration(days: 2)),
        safeDaysAfterExpiry: 5,
      ),

      // ── Expiring soon ≤ 3 days (orange) ────────────────────────
      FoodItem(
        name: 'Whole Milk',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 3)),
        safeDaysAfterExpiry: 3,
      ),
      FoodItem(
        name: 'Baby Spinach',
        category: 'Produce',
        expiryDate: today.add(const Duration(days: 3)),
        safeDaysAfterExpiry: 5,
      ),

      // ── Fresh (green) ────────────────────────────────────────────
      FoodItem(
        name: 'Greek Yogurt',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 9)),
        safeDaysAfterExpiry: 3,
      ),
      FoodItem(
        name: 'Blueberries',
        category: 'Produce',
        expiryDate: today.add(const Duration(days: 6)),
        safeDaysAfterExpiry: 5,
      ),
      FoodItem(
        name: 'Cheddar Cheese',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 22)),
        safeDaysAfterExpiry: 3,
      ),
      FoodItem(
        name: 'Butter',
        category: 'Dairy',
        expiryDate: today.add(const Duration(days: 60)),
        safeDaysAfterExpiry: 3,
      ),
      FoodItem(
        name: 'Frozen Peas',
        category: 'Frozen',
        expiryDate: today.add(const Duration(days: 180)),
        safeDaysAfterExpiry: 30,
      ),
      FoodItem(
        name: 'Canned Tomatoes',
        category: 'Canned Goods',
        expiryDate: today.add(const Duration(days: 540)),
        safeDaysAfterExpiry: 365,
      ),
    ];
  }

  /// Inserts demo food items into the local database.
  static Future<void> seed(DatabaseService db) async {
    final items = _buildItems();
    for (final item in items) {
      await db.insertFoodItem(item);
    }
  }
}
