import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../../acceptance/providers/acceptance_provider.dart';
import '../providers/invoice_provider.dart';

class InvoiceReviewScreen extends ConsumerWidget {
  final String orderId;
  const InvoiceReviewScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceProvider);
    final invoice = state.invoice;
    if (invoice == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    final fmt = NumberFormat('#,##0.00', 'ru');
    final suspCount = invoice.items.where((i) => i.isSuspicious).length;

    return Scaffold(
      appBar: const HalykAppBar(title: 'Проверка накладной'),
      body: Column(
        children: [
          // Шапка накладной
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (invoice.supplierName != null)
                  _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Поставщик',
                      value: invoice.supplierName!),
                if (invoice.invoiceNumber != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.tag_rounded,
                      label: 'Номер накладной',
                      value: invoice.invoiceNumber!),
                ],
                if (invoice.totalSum != null) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Итого',
                      value: '${fmt.format(invoice.totalSum!)} ₸'),
                ],
                if (suspCount > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '$suspCount позиций требуют проверки',
                          style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Список позиций
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: invoice.items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = invoice.items[i];
                return _ItemCard(
                  item: item,
                  index: i + 1,
                  onEdit: (qty, price) => ref
                      .read(invoiceProvider.notifier)
                      .patchItem(item.id, qty: qty, price: price),
                );
              },
            ),
          ),
          // Кнопка перехода к расхождениям
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
              onPressed: () async {
                await ref
                    .read(acceptanceProvider.notifier)
                    .startAcceptance(orderId);
                if (!context.mounted) return;
                final err = ref.read(acceptanceProvider).error;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.error),
                  );
                  return;
                }
                context.push('/orders/$orderId/discrepancies');
              },
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Перейти к сверке'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

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

class _ItemCard extends StatefulWidget {
  final dynamic item;
  final int index;
  final Future<void> Function(double? qty, double? price) onEdit;

  const _ItemCard(
      {required this.item, required this.index, required this.onEdit});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _expanded = false;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl =
        TextEditingController(text: widget.item.qty.toStringAsFixed(0));
    _priceCtrl =
        TextEditingController(text: widget.item.price.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSusp = item.isSuspicious;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSusp
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.divider,
          width: isSusp ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSusp
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isSusp
                          ? const Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.warning)
                          : Text('${widget.index}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        if (item.barcode != null)
                          Text('ШК: ${item.barcode}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.qty.toStringAsFixed(0)} ${item.unit}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      ),
                      Text(
                        '${item.price.toStringAsFixed(0)} ₸',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Редактировать',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Кол-во',
                            suffixText: item.unit,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Цена',
                            suffixText: '₸',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              await widget.onEdit(
                                double.tryParse(_qtyCtrl.text),
                                double.tryParse(_priceCtrl.text),
                              );
                              if (mounted) {
                                setState(() {
                                  _saving = false;
                                  _expanded = false;
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40)),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
