import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/food_item.dart';
import '../services/cloud_sync_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/transitions.dart';
import '../widgets/food_card.dart';
import 'add_item_screen.dart';
import 'calendar_screen.dart';
import 'item_detail_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

const List<String> kCategories = [
  'All',
  'Produce',
  'Dairy',
  'Meat',
  'Seafood',
  'Bakery',
  'Beverages',
  'Snacks',
  'Frozen',
  'Canned Goods',
  'Other',
];

// Order in which categories appear on the home screen
const List<String> kCategoryOrder = [
  'Produce',
  'Dairy',
  'Meat',
  'Seafood',
  'Bakery',
  'Beverages',
  'Snacks',
  'Frozen',
  'Canned Goods',
  'Other',
];

const Map<String, String> kCategoryEmoji = {
  'Produce': '🥦',
  'Dairy': '🥛',
  'Meat': '🥩',
  'Seafood': '🐟',
  'Bakery': '🍞',
  'Beverages': '🥤',
  'Snacks': '🍿',
  'Frozen': '❄️',
  'Canned Goods': '🥫',
  'Other': '📦',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _SortOption { expiryDate, name, category }

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<FoodItem> _foodItems = [];
  FoodItem? _pendingDelete;
  final DatabaseService _db = DatabaseService();

  late final AnimationController _listAnimController;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  _SortOption _sortOption = _SortOption.expiryDate;

  @override
  void initState() {
    super.initState();
    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadItems();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    // Re-sync whenever auth state changes (sign in / sign out)
    if (!kIsWeb) {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) _syncFromCloud();
      });
    }
  }

  /// On sign-in: merge cloud items into local DB, then upload any local-only items.
  Future<void> _syncFromCloud() async {
    final cloudItems = await CloudSyncService.fetchAll();
    final localItems = await _db.getAllFoodItems();
    final localIds = localItems.map((e) => e.id).toSet();

    if (cloudItems.isNotEmpty) {
      // Insert cloud items that don't exist locally
      for (final item in cloudItems) {
        if (!localIds.contains(item.id)) {
          await _db.insertFoodItem(item);
        }
      }
      // Upload any local items not yet in cloud
      final cloudIds = cloudItems.map((e) => e.id).toSet();
      final localOnly = localItems.where((e) => !cloudIds.contains(e.id)).toList();
      if (localOnly.isNotEmpty) {
        final allItems = await _db.getAllFoodItems();
        await CloudSyncService.uploadAll(allItems);
      }
    } else {
      // Cloud is empty — upload everything local
      await CloudSyncService.uploadAll(localItems);
    }
    _loadItems();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await _db.getAllFoodItems();
    setState(() => _foodItems = items);
    _listAnimController.forward(from: 0);
  }

  Future<void> _hardDeleteItem(FoodItem item) async {
    await _db.deleteFoodItem(item.id!);
    await NotificationService.cancelNotifications(item.id!);
  }

  void _softDelete(FoodItem item) {
    // Flush any previous pending delete immediately
    if (_pendingDelete != null) {
      _hardDeleteItem(_pendingDelete!);
    }
    setState(() {
      _foodItems.remove(item);
      _pendingDelete = item;
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(SnackBar(
      content: Text('${item.name} deleted'),
      duration: const Duration(seconds: 4),
      backgroundColor: AppColors.surface,
      action: SnackBarAction(
        label: 'Undo',
        textColor: AppColors.primary,
        onPressed: () {
          setState(() {
            _foodItems.add(_pendingDelete!);
            _foodItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
            _pendingDelete = null;
          });
        },
      ),
    ));

    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action && _pendingDelete != null) {
        _hardDeleteItem(_pendingDelete!);
        _pendingDelete = null;
      }
    });
  }

  List<FoodItem> get _filteredItems {
    final filtered = _foodItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case _SortOption.expiryDate:
        filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      case _SortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case _SortOption.category:
        filtered.sort((a, b) => a.category.compareTo(b.category));
    }
    return filtered;
  }

  /// Groups items by category in the preferred display order.
  Map<String, List<FoodItem>> _groupedItems(List<FoodItem> items) {
    final Map<String, List<FoodItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    // Return in the preferred order, skipping empty categories
    final ordered = <String, List<FoodItem>>{};
    for (final cat in kCategoryOrder) {
      if (grouped.containsKey(cat)) {
        ordered[cat] = grouped[cat]!;
      }
    }
    // Any category not in the order list goes last
    for (final entry in grouped.entries) {
      if (!ordered.containsKey(entry.key)) {
        ordered[entry.key] = entry.value;
      }
    }
    return ordered;
  }

  Widget _buildSummaryBanner() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekFromNow = today.add(const Duration(days: 7));

    final expired = _foodItems.where((i) => i.isExpired && !i.isStillSafe).length;
    final expToday = _foodItems.where((i) {
      final d = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return !i.isExpired && d == today;
    }).length;
    final expWeek = _foodItems.where((i) {
      final d = DateTime(i.expiryDate.year, i.expiryDate.month, i.expiryDate.day);
      return !i.isExpired && d.isAfter(today) && !d.isAfter(weekFromNow);
    }).length;

    if (expired == 0 && expToday == 0 && expWeek == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 12,
              children: [
                if (expired > 0)
                  Text('$expired expired',
                      style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600)),
                if (expToday > 0)
                  Text('$expToday expiring today',
                      style: const TextStyle(fontSize: 13, color: AppColors.warning, fontWeight: FontWeight.w600)),
                if (expWeek > 0)
                  Text('$expWeek expiring this week',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final filtered = _filteredItems;
    final grouped = _groupedItems(filtered);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Fridge',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_foodItems.length} item${_foodItems.length == 1 ? '' : 's'} tracked',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sort button
                  PopupMenuButton<_SortOption>(
                    onSelected: (val) => setState(() => _sortOption = val),
                    color: AppColors.surface,
                    icon: const Icon(Icons.sort, color: AppColors.textSecondary),
                    itemBuilder: (_) => [
                      _buildSortMenuItem(_SortOption.expiryDate, 'Expiry Date', Icons.calendar_today_outlined),
                      _buildSortMenuItem(_SortOption.name, 'Name', Icons.sort_by_alpha),
                      _buildSortMenuItem(_SortOption.category, 'Category', Icons.category_outlined),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search food items...',
                  hintStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Category filter chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = kCategories[index];
                    final selected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Expiry summary banner
        _buildSummaryBanner(),

        // Grouped list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.kitchen_outlined,
                          size: 72,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        _foodItems.isEmpty
                            ? 'No items yet'
                            : 'No items match your search',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_foodItems.isEmpty)
                        const Text(
                          'Tap + to add your first item',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 100),
                  itemCount: grouped.length,
                  itemBuilder: (context, sectionIndex) {
                    final category =
                        grouped.keys.elementAt(sectionIndex);
                    final items = grouped[category]!;
                    final emoji =
                        kCategoryEmoji[category] ?? '📦';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              20, 16, 20, 4),
                          child: Row(
                            children: [
                              Text(
                                emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${items.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Items in this category
                        ...items.asMap().entries.map((entry) {
                              final idx = entry.key.clamp(0, 8);
                              final item = entry.value;
                              final animation = CurvedAnimation(
                                parent: _listAnimController,
                                curve: Interval(
                                  idx * 0.07,
                                  (idx * 0.07 + 0.5).clamp(0.0, 1.0),
                                  curve: Curves.easeOut,
                                ),
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.12),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: Dismissible(
                                    key: ValueKey(item.id),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) => _softDelete(item),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                                      ),
                                      child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 26),
                                    ),
                                    child: FoodCard(
                                      item: item,
                                      onDelete: () => _softDelete(item),
                                      onEdit: () async {
                                        await Navigator.push(
                                          context,
                                          slideUpFadeRoute(AddItemScreen(existingItem: item)),
                                        );
                                        _loadItems();
                                      },
                                      onTap: () => Navigator.push(
                                        context,
                                        slideUpFadeRoute(ItemDetailScreen(
                                          item: item,
                                          onDelete: () => _softDelete(item),
                                          onEdit: () async {
                                            await Navigator.push(
                                              context,
                                              slideUpFadeRoute(AddItemScreen(existingItem: item)),
                                            );
                                            _loadItems();
                                          },
                                        )),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  PopupMenuItem<_SortOption> _buildSortMenuItem(_SortOption option, String label, IconData icon) {
    final selected = _sortOption == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textPrimary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _currentIndex == 0
          ? _buildHomeTab()
          : _currentIndex == 1
              ? CalendarScreen(foodItems: _foodItems)
              : _currentIndex == 2
                  ? StatsScreen(foodItems: _foodItems)
                  : ProfileScreen(foodItems: _foodItems),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  slideUpFadeRoute(const AddItemScreen()),
                );
                if (saved == true) _loadItems();
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600);
          }
          return const TextStyle(
              color: AppColors.textSecondary, fontSize: 12);
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
