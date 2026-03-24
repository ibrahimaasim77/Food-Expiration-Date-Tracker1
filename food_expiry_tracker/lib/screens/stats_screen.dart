import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/food_item.dart';

class StatsScreen extends StatefulWidget {
  final List<FoodItem> foodItems;
  const StatsScreen({super.key, required this.foodItems});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedCategoryIndex = -1;
  int _touchedStatusIndex = -1;

  // ── computed helpers ────────────────────────────────────────────────────────

  Map<String, int> get _categoryCount {
    final map = <String, int>{};
    for (final item in widget.foodItems) {
      map[item.category] = (map[item.category] ?? 0) + 1;
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, int> get _statusCount {
    int fresh = 0, expiringSoon = 0, stillSafe = 0, unsafe = 0;
    for (final item in widget.foodItems) {
      if (item.isExpired && !item.isStillSafe) {
        unsafe++;
      } else if (item.isExpired && item.isStillSafe) {
        stillSafe++;
      } else if (item.daysUntilExpiry <= 3) {
        expiringSoon++;
      } else {
        fresh++;
      }
    }
    return {
      if (fresh > 0) 'Fresh': fresh,
      if (expiringSoon > 0) 'Expiring Soon': expiringSoon,
      if (stillSafe > 0) 'Still Safe': stillSafe,
      if (unsafe > 0) 'Unsafe': unsafe,
    };
  }

  List<FoodItem> get _expiringSoon {
    final now = DateTime.now();
    return widget.foodItems
        .where((i) =>
            !i.isExpired &&
            i.expiryDate.difference(now).inDays <= 7)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  String get _topCategory {
    if (_categoryCount.isEmpty) return '—';
    return _categoryCount.entries.first.key;
  }

  int get _freshCount =>
      widget.foodItems.where((i) => !i.isExpired).length;

  // ── chart colors ────────────────────────────────────────────────────────────

  static const _categoryColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF8BC34A),
    Color(0xFFFFEB3B),
    Color(0xFF607D8B),
  ];

  static const _statusColors = {
    'Fresh': Color(0xFF2196F3),
    'Expiring Soon': Color(0xFFFF9800),
    'Still Safe': Color(0xFF4CAF50),
    'Unsafe': Color(0xFFE53935),
  };

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.foodItems.isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
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
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.foodItems.length} item${widget.foodItems.length == 1 ? '' : 's'} tracked',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          if (isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No data yet',
                        style: TextStyle(
                            fontSize: 18, color: AppColors.textSecondary)),
                    SizedBox(height: 8),
                    Text('Add food items to see your stats',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 20),

            // Summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSummaryCards(),
            ),

            const SizedBox(height: 24),

            // Category pie chart
            _sectionHeader('By Category'),
            _buildCategoryChart(),

            const SizedBox(height: 24),

            // Status pie chart
            _sectionHeader('By Status'),
            _buildStatusChart(),

            // Expiring soon list
            if (_expiringSoon.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader('Expiring Within 7 Days'),
              _buildExpiringSoonList(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final expiredThisMonth = widget.foodItems
        .where((i) => i.isExpired && i.expiryDate.isAfter(monthStart))
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Total', value: '${widget.foodItems.length}', icon: Icons.kitchen_outlined, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'Fresh', value: '$_freshCount', icon: Icons.check_circle_outline, color: const Color(0xFF2196F3))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Expired This Month', value: '$expiredThisMonth', icon: Icons.event_busy_outlined, color: AppColors.danger)),
            const SizedBox(width: 12),
            Expanded(child: _SummaryCard(label: 'Top Category', value: _topCategory, icon: Icons.category_outlined, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    final categories = _categoryCount;
    if (categories.isEmpty) return const SizedBox.shrink();

    final keys = categories.keys.toList();
    final sections = keys.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value;
      final count = categories[cat]!;
      final isTouched = i == _touchedCategoryIndex;
      return PieChartSectionData(
        value: count.toDouble(),
        color: _categoryColors[i % _categoryColors.length],
        radius: isTouched ? 72 : 60,
        title: isTouched ? '$count' : '',
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 48,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedCategoryIndex = -1;
                          return;
                        }
                        _touchedCategoryIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: keys.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final count = categories[cat]!;
                return _LegendItem(
                  color: _categoryColors[i % _categoryColors.length],
                  label: '$cat ($count)',
                  bold: i == _touchedCategoryIndex,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart() {
    final statuses = _statusCount;
    if (statuses.isEmpty) return const SizedBox.shrink();

    final keys = statuses.keys.toList();
    final sections = keys.asMap().entries.map((entry) {
      final i = entry.key;
      final status = entry.value;
      final count = statuses[status]!;
      final isTouched = i == _touchedStatusIndex;
      return PieChartSectionData(
        value: count.toDouble(),
        color: _statusColors[status] ?? AppColors.primary,
        radius: isTouched ? 72 : 60,
        title: isTouched ? '$count' : '',
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 48,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedStatusIndex = -1;
                          return;
                        }
                        _touchedStatusIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: keys.asMap().entries.map((entry) {
                final i = entry.key;
                final status = entry.value;
                final count = statuses[status]!;
                return _LegendItem(
                  color: _statusColors[status] ?? AppColors.primary,
                  label: '$status ($count)',
                  bold: i == _touchedStatusIndex,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringSoonList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: _expiringSoon.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final days = item.daysUntilExpiry;
            final color = days == 0
                ? AppColors.danger
                : days <= 3
                    ? AppColors.warning
                    : AppColors.primary;
            return Column(
              children: [
                if (i > 0)
                  const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            days == 0 ? '!' : '$days',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text(item.category,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        days == 0
                            ? 'Today'
                            : days == 1
                                ? 'Tomorrow'
                                : 'In $days days',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── small reusable widgets ────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool bold;

  const _LegendItem(
      {required this.color, required this.label, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
