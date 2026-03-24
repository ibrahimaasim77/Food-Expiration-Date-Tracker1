import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import 'cloud_sync_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ── SQLite (mobile) ────────────────────────────────────────────────────────

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'food_expiry.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE food_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            expiryDate TEXT NOT NULL,
            category TEXT NOT NULL,
            safeDaysAfterExpiry INTEGER NOT NULL,
            imagePath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE food_items ADD COLUMN imagePath TEXT');
        }
      },
    );
  }

  // ── SharedPreferences (web) ────────────────────────────────────────────────

  static const _webKey = 'food_items_json';

  Future<List<FoodItem>> _webGetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FoodItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  Future<void> _webSaveAll(List<FoodItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _webKey, jsonEncode(items.map((e) => e.toMap()).toList()));
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<int> insertFoodItem(FoodItem item) async {
    if (kIsWeb) {
      final items = await _webGetAll();
      final id = DateTime.now().millisecondsSinceEpoch;
      final saved = FoodItem(
        id: id,
        name: item.name,
        expiryDate: item.expiryDate,
        category: item.category,
        safeDaysAfterExpiry: item.safeDaysAfterExpiry,
        imagePath: item.imagePath,
      );
      items.add(saved);
      await _webSaveAll(items);
      CloudSyncService.saveItem(saved);
      return id;
    }
    final db = await database;
    final id = await db.insert('food_items', item.toMap());
    final saved = FoodItem(
      id: id,
      name: item.name,
      expiryDate: item.expiryDate,
      category: item.category,
      safeDaysAfterExpiry: item.safeDaysAfterExpiry,
      imagePath: item.imagePath,
    );
    CloudSyncService.saveItem(saved);
    return id;
  }

  Future<List<FoodItem>> getAllFoodItems() async {
    if (kIsWeb) return _webGetAll();
    final db = await database;
    final maps = await db.query('food_items', orderBy: 'expiryDate ASC');
    return maps.map((map) => FoodItem.fromMap(map)).toList();
  }

  Future<void> deleteFoodItem(int id) async {
    if (kIsWeb) {
      final items = await _webGetAll();
      items.removeWhere((i) => i.id == id);
      await _webSaveAll(items);
      CloudSyncService.deleteItem(id);
      return;
    }
    final db = await database;
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
    CloudSyncService.deleteItem(id);
  }

  Future<void> updateFoodItem(FoodItem item) async {
    if (kIsWeb) {
      final items = await _webGetAll();
      final idx = items.indexWhere((i) => i.id == item.id);
      if (idx != -1) items[idx] = item;
      await _webSaveAll(items);
      CloudSyncService.saveItem(item);
      return;
    }
    final db = await database;
    await db.update(
      'food_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    CloudSyncService.saveItem(item);
  }
}
