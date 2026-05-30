import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/invoice_model.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../../invoice/providers/invoice_provider.dart';
import '../providers/acceptance_provider.dart';

class DiscrepancyScreen extends ConsumerStatefulWidget {
  final String orderId;
  const DiscrepancyScreen({super.key, required this.orderId});

  @override
  ConsumerState<DiscrepancyScreen> createState() => _DiscrepancyScreenState();
}

class _DiscrepancyScreenState extends ConsumerState<DiscrepancyScreen> {
  bool _isSaving = false;

  Future<void> _finish() async {
    final invoice = ref.read(invoiceProvider).invoice;
    if (invoice == null) return;
    setState(() => _isSaving = true);
    final ok = await ref
        .read(acceptanceProvider.notifier)
        .saveAndFinish(invoice.items);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) return;

    final state = ref.read(acceptanceProvider);
    if (state.hasDiscrepancies && state.originalSum != null) {
      context.push('/orders/${widget.orderId}/act');
    } else {
      context.go('/orders/${widget.orderId}/done');
    }
  }

  @override
  Widget build(BuildContext context, ) {
    final invoice = ref.watch(invoiceProvider).invoice;
    final accState = ref.watch(acceptanceProvider);
    final items = invoice?.items ?? [];

    return Scaffold(
      appBar: const HalykAppBar(title: 'Сверка товаров'),
      body: Column(
        children: [
          // Прогресс
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('${items.length} позиций',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Text(
                  '${accState.itemStatuses.length} отмечено',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DiscrepancyItemCard(
                item: items[i],
                orderId: widget.orderId,
              ),
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
            child: Column(
              children: [
                if (accState.error != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(accState.error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _finish,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSaving ? 'Сохраняем...' : 'Завершить приёмку'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscrepancyItemCard extends ConsumerStatefulWidget {
  final InvoiceItem item;
  final String orderId;
  const _DiscrepancyItemCard({required this.item, required this.orderId});

  @override
  ConsumerState<_DiscrepancyItemCard> createState() =>
      _DiscrepancyItemCardState();
}

class _DiscrepancyItemCardState extends ConsumerState<_DiscrepancyItemCard> {
  DiscType _selected = DiscType.ok;
  final _qtyCtrl = TextEditingController();
  String? _photoPath;
  bool _recognizing = false;
  int? _recognizedCount;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndRecognize() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, maxWidth: 1280, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _photoPath = picked.path;
      _recognizing = true;
    });

    final result = await ref
        .read(acceptanceProvider.notifier)
        .recognizeImage(picked.path);

    final count = result['count'] as int?;
    setState(() {
      _recognizing = false;
      if (count != null) {
        _recognizedCount = count;
        _qtyCtrl.text = count.toString();
      }
    });

    _save();
  }

  void _save() {
    double? qty = double.tryParse(_qtyCtrl.text);
    ref.read(acceptanceProvider.notifier).setItemStatus(
          widget.item,
          _selected,
          qtyActual: _selected == DiscType.surplus
              ? (widget.item.qty + (qty ?? 0))
              : _selected == DiscType.shortage
                  ? (widget.item.qty - (qty ?? 0))
                  : null,
          qtyDefect: _selected == DiscType.defect ? qty : null,
          photoUrl: _photoPath,
        );
  }

  Color get _statusColor => switch (_selected) {
        DiscType.ok => AppColors.statusOk,
        DiscType.shortage => AppColors.statusShortage,
        DiscType.surplus => AppColors.statusSurplus,
        DiscType.defect => AppColors.statusDefect,
        DiscType.misgrade => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _selected == DiscType.ok
              ? AppColors.divider
              : _statusColor.withValues(alpha: 0.5),
          width: _selected == DiscType.ok ? 1 : 1.5,
        ),
      ),
      child: Column(
        children: [
          // Заголовок позиции
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      color: _statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Text(
                          'Ожидается: ${widget.item.qty.toStringAsFixed(0)} ${widget.item.unit}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Выбор типа
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: DiscType.values.map((t) {
                final isSelected = _selected == t;
                final color = switch (t) {
                  DiscType.ok => AppColors.statusOk,
                  DiscType.shortage => AppColors.statusShortage,
                  DiscType.surplus => AppColors.statusSurplus,
                  DiscType.defect => AppColors.statusDefect,
                  DiscType.misgrade => AppColors.textSecondary,
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = t;
                        if (t == DiscType.ok) {
                          _qtyCtrl.clear();
                          _photoPath = null;
                          _recognizedCount = null;
                        }
                      });
                      if (t == DiscType.ok) _save();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            switch (t) {
                              DiscType.ok =>
                                Icons.check_circle_rounded,
                              DiscType.shortage =>
                                Icons.remove_circle_rounded,
                              DiscType.surplus =>
                                Icons.add_circle_rounded,
                              DiscType.defect =>
                                Icons.broken_image_rounded,
                              DiscType.misgrade =>
                                Icons.swap_horiz_rounded,
                            },
                            color: isSelected ? Colors.white : color,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Доп поля
          if (_selected != DiscType.ok) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _buildExtraFields(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraFields() {
    if (_selected == DiscType.defect || _selected == DiscType.surplus) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кнопка камеры
          GestureDetector(
            onTap: _recognizing ? null : _pickAndRecognize,
            child: Container(
              height: _photoPath != null ? 140 : 80,
              decoration: BoxDecoration(
                color: AppColors.statusDefect.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        AppColors.statusDefect.withValues(alpha: 0.3)),
              ),
              child: _recognizing
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: AppColors.primary),
                          SizedBox(height: 8),
                          Text('ИИ считает товар...',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  : _photoPath != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_photoPath!),
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                color: AppColors.statusDefect, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              _selected == DiscType.defect
                                  ? 'Сфотографировать брак (ИИ посчитает)'
                                  : 'Сфотографировать излишек (ИИ посчитает)',
                              style: const TextStyle(
                                  color: AppColors.statusDefect,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
            ),
          ),
          if (_recognizedCount != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text('ИИ распознал: $_recognizedCount шт.',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _qtyCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => _save(),
            decoration: InputDecoration(
              labelText: _selected == DiscType.defect
                  ? 'Количество брака'
                  : 'Количество излишка',
              suffixText: widget.item.unit,
              helperText: 'Можно исправить вручную',
              isDense: true,
            ),
          ),
        ],
      );
    }

    // Недостача и пересорт — только количество вручную
    return TextField(
      controller: _qtyCtrl,
      keyboardType: TextInputType.number,
      onChanged: (_) => _save(),
      decoration: InputDecoration(
        labelText: _selected == DiscType.shortage
            ? 'Сколько не хватает'
            : 'Количество',
        suffixText: widget.item.unit,
        helperText:
            'Ожидается: ${widget.item.qty.toStringAsFixed(0)} ${widget.item.unit}',
        isDense: true,
      ),
    );
  }
}
