import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';

/// Syncs food items to Firebase Realtime Database under the signed-in user's UID.
/// Structure: /users/{uid}/food_items/{localId} → item fields
class CloudSyncService {
  static FirebaseDatabase? get _rtdb => kIsWeb ? null : FirebaseDatabase.instance;

  static String? get _uid => kIsWeb ? null : FirebaseAuth.instance.currentUser?.uid;

  static DatabaseReference? get _ref =>
      (_uid != null && _rtdb != null) ? _rtdb!.ref('users/$_uid/food_items') : null;

  static bool get isSignedIn => _uid != null;

  /// Save or update a single item in the cloud.
  static Future<void> saveItem(FoodItem item) async {
    if (_ref == null || item.id == null) return;
    await _ref!.child('${item.id}').set({
      'name': item.name,
      'expiryDate': item.expiryDate.toIso8601String(),
      'category': item.category,
      'safeDaysAfterExpiry': item.safeDaysAfterExpiry,
    });
  }

  /// Delete a single item from the cloud.
  static Future<void> deleteItem(int id) async {
    if (_ref == null) return;
    await _ref!.child('$id').remove();
  }

  /// Upload all local items to the cloud (replaces existing cloud data).
  static Future<void> uploadAll(List<FoodItem> items) async {
    if (_ref == null) return;
    final Map<String, dynamic> data = {};
    for (final item in items) {
      if (item.id != null) {
        data['${item.id}'] = {
          'name': item.name,
          'expiryDate': item.expiryDate.toIso8601String(),
          'category': item.category,
          'safeDaysAfterExpiry': item.safeDaysAfterExpiry,
        };
      }
    }
    await _ref!.set(data.isEmpty ? null : data);
  }

  /// Fetch all items stored in the cloud for the current user.
  /// Returns an empty list if nothing is stored yet.
  static Future<List<FoodItem>> fetchAll() async {
    if (_ref == null) return [];
    final snapshot = await _ref!.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    final items = <FoodItem>[];
    for (final entry in raw.entries) {
      try {
        final map = Map<String, dynamic>.from(entry.value as Map);
        items.add(FoodItem(
          id: int.tryParse(entry.key),
          name: map['name'] as String,
          expiryDate: DateTime.parse(map['expiryDate'] as String),
          category: map['category'] as String,
          safeDaysAfterExpiry: map['safeDaysAfterExpiry'] as int,
        ));
      } catch (_) {
        // skip malformed entries
      }
    }
    return items;
  }
}
