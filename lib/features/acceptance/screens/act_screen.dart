import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../providers/acceptance_provider.dart';

class ActScreen extends ConsumerWidget {
  final String orderId;
  const ActScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(acceptanceProvider);
    final fmt = NumberFormat('#,##0.00', 'ru');

    final original = state.originalSum ?? 0;
    final corrected = state.correctedSum ?? 0;
    final delta = state.totalDelta ?? 0;

    return Scaffold(
      appBar: const HalykAppBar(title: 'Акт расхождений'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Сводка сумм
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Итоговые суммы',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _SumRow(
                          label: 'По накладной',
                          value: '${fmt.format(original)} ₸',
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(height: 10),
                        _SumRow(
                          label: 'К оплате (скорр.)',
                          value: '${fmt.format(corrected)} ₸',
                          color: AppColors.primary,
                          bold: true,
                        ),
                        const Divider(height: 20),
                        _SumRow(
                          label: 'Разница',
                          value: '${delta < 0 ? '' : '+'}${fmt.format(delta)} ₸',
                          color: delta < 0
                              ? AppColors.statusDefect
                              : AppColors.statusSurplus,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Список расхождений
                const Text(
                  'Расхождения',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ...state.itemStatuses.values
                    .where((d) => d.type != DiscType.ok)
                    .map((d) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.divider)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(d.item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.type == DiscType.defect
                                          ? 'Брак: ${d.qtyDefect?.toStringAsFixed(0) ?? '—'} ${d.item.unit}'
                                          : d.type == DiscType.shortage
                                              ? 'Недостача: факт ${d.qtyActual?.toStringAsFixed(0) ?? '—'} ${d.item.unit}'
                                              : d.type == DiscType.surplus
                                                  ? 'Излишек: факт ${d.qtyActual?.toStringAsFixed(0) ?? '—'} ${d.item.unit}'
                                                  : 'Пересорт',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _discColor(d.type)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  d.type.label,
                                  style: TextStyle(
                                      color: _discColor(d.type),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        )),
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
                    offset: const Offset(0, -4))
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      await ref
                          .read(acceptanceProvider.notifier)
                          .confirmAct();
                      if (!context.mounted) return;
                      context.go('/orders/$orderId/done');
                    },
              icon: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded),
              label: const Text('Подтвердить и оприходовать'),
            ),
          ),
        ],
      ),
    );
  }

  Color _discColor(DiscType t) => switch (t) {
        DiscType.defect => AppColors.statusDefect,
        DiscType.shortage => AppColors.statusShortage,
        DiscType.surplus => AppColors.statusSurplus,
        DiscType.misgrade => AppColors.textSecondary,
        DiscType.ok => AppColors.statusOk,
      };
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _SumRow(
      {required this.label,
      required this.value,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 14,
                color: color)),
      ],
    );
  }
}
