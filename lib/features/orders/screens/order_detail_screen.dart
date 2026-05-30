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
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt);
    final canScan = order.status != OrderStatus.closed &&
        order.status != OrderStatus.cancelled;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(order: order, dateStr: dateStr),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Список товаров',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${order.items.length} поз.',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...order.items.asMap().entries.map(
                    (e) => _ItemRow(item: e.value, index: e.key + 1),
                  ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: canScan
                ? () {
                    ref.read(sessionProvider.notifier).startSession(order);
                    context.push('/orders/${order.id}/scan');
                  }
                : null,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Начать приёмку'),
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Order order;
  final String dateStr;
  const _HeaderCard({required this.order, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final orderNum = order.id.substring(0, 8).toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заявка #$orderNum',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.supplierName,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Дата создания',
              value: dateStr,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Позиций в заявке',
              value: '${order.items.length} шт.',
            ),
            if (order.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Сумма заявки',
                value: _totalSum(order),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _totalSum(Order order) {
    double total = 0;
    for (final item in order.items) {
      if (item.price != null) total += item.price! * item.qtyOrdered;
    }
    if (total == 0) return '—';
    return '${total.toStringAsFixed(0)} ₸';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
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
  final int index;
  const _ItemRow({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                if (item.product?.sku != null)
                  Text('Арт: ${item.product!.sku}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                if (item.product?.barcode != null)
                  Text('ШК: ${item.product!.barcode}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.qtyOrdered.toStringAsFixed(0),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary),
              ),
              Text(
                item.product?.unit ?? 'шт',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
              if (item.price != null)
                Text(
                  '${item.price!.toStringAsFixed(0)} ₸',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
