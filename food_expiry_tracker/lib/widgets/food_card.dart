import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../models/food_item.dart';

class FoodCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onTap;

  const FoodCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    this.onTap,
  });

  Color _getStatusColor() {
    if (item.isExpired && !item.isStillSafe) return AppColors.danger;
    if (item.isExpired && item.isStillSafe) return AppColors.warning;
    if (item.daysUntilExpiry <= 3) return AppColors.warning;
    return AppColors.primary;
  }

  IconData _getStatusIcon() {
    if (item.isExpired && !item.isStillSafe) return Icons.cancel;
    if (item.isExpired && item.isStillSafe) return Icons.warning_amber;
    if (item.daysUntilExpiry <= 3) return Icons.warning_amber;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail or status icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imagePath != null && !kIsWeb
                  ? Image.file(
                      File(item.imagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getStatusIcon(),
                          color: statusColor, size: 26),
                    ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Text(
                    item.statusMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.textSecondary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.textSecondary),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
      ),
    );
  }
}
