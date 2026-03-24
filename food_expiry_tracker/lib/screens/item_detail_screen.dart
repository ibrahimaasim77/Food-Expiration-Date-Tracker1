import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../models/food_item.dart';

class ItemDetailScreen extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  Color get _statusColor {
    if (item.isExpired && !item.isStillSafe) return AppColors.danger;
    if (item.isExpired || item.daysUntilExpiry <= 3) return AppColors.warning;
    return AppColors.primary;
  }

  IconData get _statusIcon {
    if (item.isExpired && !item.isStillSafe) return Icons.cancel;
    if (item.isExpired || item.daysUntilExpiry <= 3) return Icons.warning_amber;
    return Icons.check_circle;
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete item?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Remove "${item.name}" from your fridge?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imagePath != null;
    final daysLeft = item.daysUntilExpiry;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar / hero image
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.textPrimary,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage && !kIsWeb
                  ? Image.file(
                      File(item.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderHero(),
                    )
                  : _placeholderHero(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _statusColor.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Icon(_statusIcon, color: _statusColor, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          item.statusMessage,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress bar (0 = expired, 1 = far away)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (daysLeft / 30).clamp(0.0, 1.0),
                            backgroundColor:
                                AppColors.surface,
                            valueColor:
                                AlwaysStoppedAnimation(_statusColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info rows
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Expiry Date',
                      value: DateFormat('MMMM d, yyyy').format(item.expiryDate),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Safe After Expiry',
                      value: '${item.safeDaysAfterExpiry} days',
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _InfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: item.category,
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text('Edit Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Delete Item'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderHero() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _statusColor.withValues(alpha: 0.25),
            AppColors.card,
          ],
        ),
      ),
      child: Center(
        child: Icon(_statusIcon, color: _statusColor, size: 72),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
