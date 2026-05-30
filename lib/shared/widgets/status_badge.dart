import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/scan_result_model.dart';
import '../../data/models/order_model.dart';

class ScanStatusBadge extends StatelessWidget {
  final ScanStatus status;

  const ScanStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      ScanStatus.ok => (AppColors.statusOk, Icons.check_circle_rounded),
      ScanStatus.defect => (AppColors.statusDefect, Icons.broken_image_rounded),
      ScanStatus.shortage => (AppColors.statusShortage, Icons.remove_circle_rounded),
      ScanStatus.surplus => (AppColors.statusSurplus, Icons.add_circle_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.newOrder => AppColors.primary,
      OrderStatus.shipped => AppColors.statusSurplus,
      OrderStatus.receiving => AppColors.warning,
      OrderStatus.accepted => AppColors.success,
      OrderStatus.discrepancy => AppColors.statusDefect,
      OrderStatus.closed => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
