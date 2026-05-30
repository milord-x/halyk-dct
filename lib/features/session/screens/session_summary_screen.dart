import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/scan_result_model.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/session_provider.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final String orderId;
  const SessionSummaryScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      appBar: HalykAppBar(
        title: 'Сводка приёмки',
        actions: [
          if (session.records.isNotEmpty && !session.isSaved)
            TextButton(
              onPressed: session.isSaving
                  ? null
                  : () => _confirmSave(context, ref, session),
              child: const Text(
                'Завершить',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
        ],
      ),
      body: session.records.isEmpty
          ? _EmptySession(orderId: orderId)
          : _SessionContent(session: session, orderId: orderId),
    );
  }

  void _confirmSave(
      BuildContext context, WidgetRef ref, SessionState session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ConfirmSheet(
        session: session,
        onConfirm: () async {
          Navigator.pop(context);
          await ref.read(sessionProvider.notifier).saveSession();
          if (!context.mounted) return;
          final saved = ref.read(sessionProvider).isSaved;
          if (saved) _showSuccessDialog(context, ref);
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Приёмка завершена!',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Данные успешно отправлены\nв базу данных',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(sessionProvider.notifier).reset();
                  context.go('/orders');
                },
                child: const Text('К списку заявок'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionContent extends StatelessWidget {
  final SessionState session;
  final String orderId;

  const _SessionContent({required this.session, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final counts = <ScanStatus, int>{};
    for (final r in session.records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }

    return Column(
      children: [
        _SummaryHeader(
          orderId: session.activeOrder?.id ?? orderId,
          total: session.records.length,
          counts: counts,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: session.records.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _RecordCard(record: session.records[i]),
          ),
        ),
        if (!session.isSaved)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Продолжить сканирование'),
            ),
          ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final String orderId;
  final int total;
  final Map<ScanStatus, int> counts;

  const _SummaryHeader({
    required this.orderId,
    required this.total,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final orderNum = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Заявка #$orderNum',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Всего: $total позиций',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(
                  label: 'Норма',
                  count: counts[ScanStatus.ok] ?? 0,
                  color: AppColors.statusOk),
              const SizedBox(width: 8),
              _StatTile(
                  label: 'Брак',
                  count: counts[ScanStatus.defect] ?? 0,
                  color: AppColors.statusDefect),
              const SizedBox(width: 8),
              _StatTile(
                  label: 'Недостача',
                  count: counts[ScanStatus.shortage] ?? 0,
                  color: AppColors.statusShortage),
              const SizedBox(width: 8),
              _StatTile(
                  label: 'Излишек',
                  count: counts[ScanStatus.surplus] ?? 0,
                  color: AppColors.statusSurplus),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatTile(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 20, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends ConsumerWidget {
  final ScanRecord record;
  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm:ss').format(record.scannedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (record.product.sku != null)
                        Text('Арт: ${record.product.sku}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ScanStatusBadge(status: record.status),
                    const SizedBox(height: 4),
                    Text(timeStr,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _QtyCol(
                      label: 'Заказано',
                      value:
                          '${record.qtyOrdered.toStringAsFixed(0)} ${record.product.unit}'),
                  const _Divider(),
                  _QtyCol(
                      label: 'Принято',
                      value:
                          '${record.qtyActual.toStringAsFixed(0)} ${record.product.unit}'),
                  if (record.qtyDiscrepancy != null &&
                      record.qtyDiscrepancy! > 0) ...[
                    const _Divider(),
                    _QtyCol(
                      label: _discLabel(record.status),
                      value:
                          '${record.qtyDiscrepancy!.toStringAsFixed(0)} ${record.product.unit}',
                      highlight: true,
                    ),
                  ],
                ],
              ),
            ),
            if (record.scanPhotoUrl != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.cloud_done_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text('Фото загружено',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _discLabel(ScanStatus s) {
    if (s == ScanStatus.shortage) return 'Недостача';
    if (s == ScanStatus.surplus) return 'Излишек';
    return 'Брак';
  }
}

class _QtyCol extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _QtyCol(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: highlight ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 28, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}

class _EmptySession extends StatelessWidget {
  final String orderId;
  const _EmptySession({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет отсканированных товаров',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Начните сканировать штрих-коды товаров',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Начать сканирование'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final SessionState session;
  final VoidCallback onConfirm;

  const _ConfirmSheet({required this.session, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final counts = <ScanStatus, int>{};
    for (final r in session.records) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.cloud_upload_rounded,
              color: AppColors.primary, size: 52),
          const SizedBox(height: 16),
          const Text(
            'Завершить приёмку?',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          // Итог по статусам
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _SheetRow('Всего позиций', '${session.records.length}', AppColors.textPrimary),
                if ((counts[ScanStatus.ok] ?? 0) > 0)
                  _SheetRow('Норма', '${counts[ScanStatus.ok]}', AppColors.statusOk),
                if ((counts[ScanStatus.defect] ?? 0) > 0)
                  _SheetRow('Брак', '${counts[ScanStatus.defect]}', AppColors.statusDefect),
                if ((counts[ScanStatus.shortage] ?? 0) > 0)
                  _SheetRow('Недостача', '${counts[ScanStatus.shortage]}', AppColors.statusShortage),
                if ((counts[ScanStatus.surplus] ?? 0) > 0)
                  _SheetRow('Излишек', '${counts[ScanStatus.surplus]}', AppColors.statusSurplus),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Фото будут загружены на сервер автоматически',
            style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Сохранить и завершить'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SheetRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
