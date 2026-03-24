class FoodItem {
  final int? id;
  final String name;
  final DateTime expiryDate;
  final String category;
  final int safeDaysAfterExpiry;
  final String? imagePath;

  FoodItem({
    this.id,
    required this.name,
    required this.expiryDate,
    required this.category,
    required this.safeDaysAfterExpiry,
    this.imagePath,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;

  bool get isStillSafe => isExpired && daysUntilExpiry.abs() <= safeDaysAfterExpiry;

  String get statusMessage {
    if (!isExpired) {
      if (daysUntilExpiry == 0) return 'Expires today!';
      if (daysUntilExpiry == 1) return 'Expires tomorrow!';
      return 'Expires in $daysUntilExpiry days';
    } else if (isStillSafe) {
      final safeDaysLeft = safeDaysAfterExpiry - daysUntilExpiry.abs();
      return 'Expired — still safe for $safeDaysLeft more days';
    } else {
      return 'No longer safe to eat';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
      'safeDaysAfterExpiry': safeDaysAfterExpiry,
      'imagePath': imagePath,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      expiryDate: DateTime.parse(map['expiryDate']),
      category: map['category'],
      safeDaysAfterExpiry: map['safeDaysAfterExpiry'],
      imagePath: map['imagePath'] as String?,
    );
  }
}
