import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../session/providers/session_provider.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: const HalykAppBar(title: 'Детали заявки'),
      body: orderAsync.when(
        data: (order) => _OrderDetail(order: order),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}

class _OrderDetail extends ConsumerWidget {
  final Order order;
  const _OrderDetail({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(order.createdAt);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(order: order, dateStr: dateStr),
              const SizedBox(height: 16),
              Text(
                'Позиции заявки (${order.items.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => _ItemRow(item: item)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: order.status == OrderStatus.closed ||
                    order.status == OrderStatus.cancelled
                ? null
                : () {
                    ref.read(sessionProvider.notifier).startSession(order);
                    context.push('/orders/${order.id}/scan');
                  },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Начать сканирование'),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Order order;
  final String dateStr;
  const _InfoCard({required this.order, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row(
              icon: Icons.tag,
              label: 'Номер заявки',
              value: order.id.substring(0, 8).toUpperCase(),
            ),
            const SizedBox(height: 10),
            _Row(
              icon: Icons.business_outlined,
              label: 'Поставщик',
              value: order.supplierName,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Статус',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            _Row(
              icon: Icons.calendar_today_outlined,
              label: 'Дата создания',
              value: dateStr,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                if (item.product?.sku != null)
                  Text('Арт: ${item.product!.sku}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.qtyOrdered.toStringAsFixed(0)} ${item.product?.unit ?? 'шт'}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary),
              ),
              if (item.price != null)
                Text(
                  '${item.price!.toStringAsFixed(0)} ₸',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
