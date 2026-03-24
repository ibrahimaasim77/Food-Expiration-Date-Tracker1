import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../models/food_item.dart';

class CalendarScreen extends StatefulWidget {
  final List<FoodItem> foodItems;

  const CalendarScreen({super.key, required this.foodItems});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();

  /// Build a map of date-key → food items expiring that day.
  Map<String, List<FoodItem>> _buildExpiryMap() {
    final map = <String, List<FoodItem>>{};
    for (final item in widget.foodItems) {
      final key = _dateKey(item.expiryDate);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Color for a day based on expiry urgency.
  Color _dayColor(DateTime date, List<FoodItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;

    // If any item is no-longer-safe, danger
    final anyDanger = items.any((i) => i.isExpired && !i.isStillSafe);
    if (anyDanger || diff < 0) return AppColors.danger;

    // If expiring today or within 3 days, warning
    if (diff <= 3) return AppColors.warning;

    return AppColors.primary;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _showDayDetail(
      BuildContext context, DateTime date, List<FoodItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DayDetailSheet(date: date, items: items),
    );
  }

  Widget _buildCalendarGrid(Map<String, List<FoodItem>> expiryMap) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    // weekday: 1=Mon … 7=Sun. Convert to 0=Sun … 6=Sat grid.
    final startOffset = (firstOfMonth.weekday % 7);

    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Weekday headers
        Row(
          children: weekDays
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        // Day cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 52,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();

            final day = index - startOffset + 1;
            final date = DateTime(
                _focusedMonth.year, _focusedMonth.month, day);
            final key = _dateKey(date);
            final items = expiryMap[key] ?? [];
            final isToday = date == today;
            final hasItems = items.isNotEmpty;
            final dotColor = hasItems ? _dayColor(date, items) : null;

            return GestureDetector(
              onTap: hasItems
                  ? () => _showDayDetail(context, date, items)
                  : null,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(
                          color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: dotColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (dotColor != null) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiryMap = _buildExpiryMap();

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
              const Text(
                'Expiry Calendar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Month navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left,
                        color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calendar grid
              _buildCalendarGrid(expiryMap),
              const SizedBox(height: 8),

              // Legend
              const Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Fresh'),
                  SizedBox(width: 16),
                  _LegendDot(
                      color: AppColors.warning, label: 'Expiring soon'),
                  SizedBox(width: 16),
                  _LegendDot(color: AppColors.danger, label: 'Expired'),
                ],
              ),
            ],
          ),
        ),

        // Upcoming expiries list
        Expanded(
          child: _buildUpcomingList(expiryMap),
        ),
      ],
    );
  }

  Widget _buildUpcomingList(Map<String, List<FoodItem>> expiryMap) {
    if (expiryMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 72,
                color:
                    AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'No expiry dates yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Show sorted upcoming/past entries
    final sortedKeys = expiryMap.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final items = expiryMap[key]!;
        final date = DateTime.parse(key);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final diff = date.difference(today).inDays;
        final color = _dayColor(date, items);

        String label;
        if (diff == 0) {
          label = 'Today';
        } else if (diff == 1) {
          label = 'Tomorrow';
        } else if (diff == -1) {
          label = 'Yesterday';
        } else if (diff < 0) {
          label = '${diff.abs()}d ago';
        } else {
          label = 'In ${diff}d';
        }

        return GestureDetector(
          onTap: () => _showDayDetail(context, date, items),
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM')
                              .format(date)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map((item) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w500,
                                          color:
                                              AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w500,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final List<FoodItem> items;

  const _DayDetailSheet({required this.date, required this.items});

  Color _itemColor(FoodItem item) {
    if (item.isExpired && !item.isStillSafe) return AppColors.danger;
    if (item.isExpired && item.isStillSafe) return AppColors.warning;
    if (item.daysUntilExpiry <= 3) return AppColors.warning;
    return AppColors.primary;
  }

  String _riskLabel(FoodItem item) {
    if (!item.isExpired) return 'Safe to eat';
    if (item.isStillSafe) {
      final left =
          item.safeDaysAfterExpiry - item.daysUntilExpiry.abs();
      return 'Still safe for ~$left more day${left == 1 ? '' : 's'}';
    }
    return 'No longer safe — do not eat';
  }

  IconData _riskIcon(FoodItem item) {
    if (!item.isExpired) return Icons.check_circle_outline;
    if (item.isStillSafe) return Icons.warning_amber_outlined;
    return Icons.cancel_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date title
          Text(
            DateFormat('EEEE, MMMM d').format(date),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${items.length} item${items.length == 1 ? '' : 's'} expiring',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Items
          ...items.map((item) {
            final color = _itemColor(item);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(_riskIcon(item), color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _riskLabel(item),
                          style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
