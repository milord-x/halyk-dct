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
        title: 'Сводка сессии',
        actions: [
          if (session.records.isNotEmpty)
            TextButton(
              onPressed: () => _confirmSave(context, ref, session),
              child: const Text('Завершить',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: session.records.isEmpty
          ? _EmptySession(orderId: orderId)
          : _SessionContent(session: session, orderId: orderId),
    );
  }

  void _confirmSave(BuildContext context, WidgetRef ref, SessionState session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ConfirmSheet(
        recordCount: session.records.length,
        onConfirm: () async {
          Navigator.pop(context);
          await ref.read(sessionProvider.notifier).saveSession();
          final saved = ref.read(sessionProvider).isSaved;
          if (context.mounted && saved) {
            _showSuccessDialog(context, ref);
          }
        },
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Сессия сохранена!',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Все данные успешно\nотправлены в базу данных',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
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
        _StatsBar(counts: counts, total: session.records.length),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: session.records.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final record = session.records[i];
              return _RecordCard(record: record);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Продолжить сканирование'),
          ),
        ),
      ],
    );
  }
}

class _StatsBar extends StatelessWidget {
  final Map<ScanStatus, int> counts;
  final int total;

  const _StatsBar({required this.counts, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          _StatChip(label: 'Всего', count: total, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Норма',
              count: counts[ScanStatus.ok] ?? 0,
              color: AppColors.statusOk),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Брак',
              count: counts[ScanStatus.defect] ?? 0,
              color: AppColors.statusDefect),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Откл.',
              count: (counts[ScanStatus.shortage] ?? 0) +
                  (counts[ScanStatus.surplus] ?? 0),
              color: AppColors.statusShortage),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: color),
            ),
            Text(label,
                style: TextStyle(fontSize: 10, color: color)),
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
    final timeStr = DateFormat('HH:mm').format(record.scannedAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Факт: ${record.qtyActual} / Заказ: ${record.qtyOrdered}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const Spacer(),
                      Text(timeStr,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ScanStatusBadge(status: record.status),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => ref
                      .read(sessionProvider.notifier)
                      .removeRecord(record.id),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.textSecondary, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          Icon(Icons.qr_code_scanner,
              size: 72,
              color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Нет отсканированных товаров',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Начать сканирование'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  final int recordCount;
  final VoidCallback onConfirm;

  const _ConfirmSheet(
      {required this.recordCount, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 20),
          const Icon(Icons.save_outlined, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          const Text('Завершить сессию?',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Будет сохранено $recordCount позиций.\nДействие нельзя отменить.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onConfirm,
            child: const Text('Сохранить и завершить'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
