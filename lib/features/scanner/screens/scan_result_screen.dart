import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/scan_result_model.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../session/providers/session_provider.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ScanResultScreen({super.key, required this.orderId});

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen> {
  ScanStatus _selectedStatus = ScanStatus.ok;
  final _qtyCtrl = TextEditingController();
  final _defectQtyCtrl = TextEditingController();
  String? _defectPhotoPath;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _defectQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDefectPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _defectPhotoPath = picked.path);
  }

  void _submit() {
    final scanState = ref.read(scannerProvider);
    final product = scanState.foundProduct!;
    final session = ref.read(sessionProvider);

    final orderItem = session.activeOrder?.items.firstWhere(
      (i) => i.product?.id == product.id,
      orElse: () => OrderItem(
        id: '',
        orderId: widget.orderId,
        product: product,
        name: product.name,
        qtyOrdered: 0,
      ),
    );
    final qtyOrdered = orderItem?.qtyOrdered ?? 0;

    double qtyActual;
    double? qtyDiscrepancy;

    switch (_selectedStatus) {
      case ScanStatus.ok:
        qtyActual = qtyOrdered;
      case ScanStatus.defect:
        qtyDiscrepancy = double.tryParse(_defectQtyCtrl.text) ?? 0;
        qtyActual = qtyOrdered - qtyDiscrepancy;
      case ScanStatus.shortage:
        qtyDiscrepancy = double.tryParse(_qtyCtrl.text) ?? 0;
        qtyActual = qtyOrdered - qtyDiscrepancy;
      case ScanStatus.surplus:
        qtyDiscrepancy = double.tryParse(_qtyCtrl.text) ?? 0;
        qtyActual = qtyOrdered + qtyDiscrepancy;
    }

    ref.read(sessionProvider.notifier).addRecord(
          product: product,
          status: _selectedStatus,
          qtyOrdered: qtyOrdered,
          qtyActual: qtyActual,
          qtyDiscrepancy: qtyDiscrepancy,
          scanPhotoPath: scanState.scanPhotoPath,
          defectPhotoPath: _defectPhotoPath,
        );

    ref.read(scannerProvider.notifier).reset();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider);
    final product = scanState.foundProduct;

    if (product == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    final session = ref.watch(sessionProvider);
    final orderItem = session.activeOrder?.items.firstWhere(
      (i) => i.product?.id == product.id,
      orElse: () => OrderItem(
        id: '',
        orderId: widget.orderId,
        product: product,
        name: product.name,
        qtyOrdered: 0,
      ),
    );
    final qtyOrdered = orderItem?.qtyOrdered ?? 0;

    return Scaffold(
      appBar: const HalykAppBar(title: 'Информация о товаре'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Фото товара
          if (scanState.scanPhotoPath != null)
            _ScanPhotoCard(photoPath: scanState.scanPhotoPath!),

          // Карточка товара
          _ProductInfoCard(
            name: product.name,
            sku: product.sku,
            barcode: product.barcode,
            qtyOrdered: qtyOrdered,
            unit: product.unit,
          ),
          const SizedBox(height: 20),

          // Номер заявки
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Заявка: ${session.activeOrder?.id.substring(0, 8).toUpperCase() ?? "—"}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Выбор статуса
          const Text(
            'Статус товара',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _StatusSelector(
            selected: _selectedStatus,
            onChanged: (s) => setState(() {
              _selectedStatus = s;
              _qtyCtrl.clear();
              _defectQtyCtrl.clear();
              _defectPhotoPath = null;
            }),
          ),
          const SizedBox(height: 20),

          // Доп. поля в зависимости от статуса
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildExtraFields(qtyOrdered, product.unit),
          ),
          const SizedBox(height: 32),

          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Подтвердить'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ref.read(scannerProvider.notifier).reset();
              context.pop();
            },
            child: const Text('Отмена'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExtraFields(double qtyOrdered, String unit) {
    switch (_selectedStatus) {
      case ScanStatus.ok:
        return _OkBanner(key: const ValueKey('ok'), qtyOrdered: qtyOrdered, unit: unit);

      case ScanStatus.defect:
        return Column(
          key: const ValueKey('defect'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              icon: Icons.broken_image_rounded,
              label: 'Количество брака',
              color: AppColors.statusDefect,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _defectQtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Кол-во бракованных единиц',
                suffixText: unit,
                helperText: 'Заказано: $qtyOrdered $unit',
              ),
            ),
            const SizedBox(height: 16),
            _SectionLabel(
              icon: Icons.camera_alt_rounded,
              label: 'Фото брака',
              color: AppColors.statusDefect,
            ),
            const SizedBox(height: 8),
            _PhotoPicker(
              photoPath: _defectPhotoPath,
              onPick: _pickDefectPhoto,
              onRemove: () => setState(() => _defectPhotoPath = null),
              color: AppColors.statusDefect,
              hint: 'Сфотографировать бракованный товар',
            ),
          ],
        );

      case ScanStatus.shortage:
        return Column(
          key: const ValueKey('shortage'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              icon: Icons.remove_circle_rounded,
              label: 'Количество недостачи',
              color: AppColors.statusShortage,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Сколько единиц не хватает',
                suffixText: unit,
                helperText: 'Заказано: $qtyOrdered $unit',
              ),
            ),
          ],
        );

      case ScanStatus.surplus:
        return Column(
          key: const ValueKey('surplus'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(
              icon: Icons.add_circle_rounded,
              label: 'Количество излишка',
              color: AppColors.statusSurplus,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Сколько лишних единиц',
                suffixText: unit,
                helperText: 'Заказано: $qtyOrdered $unit',
              ),
            ),
          ],
        );
    }
  }
}

class _ScanPhotoCard extends StatelessWidget {
  final String photoPath;
  const _ScanPhotoCard({required this.photoPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text('Фото товара',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Отправлено на сервер',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(photoPath),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _OkBanner extends StatelessWidget {
  final double qtyOrdered;
  final String unit;
  const _OkBanner({super.key, required this.qtyOrdered, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusOk.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statusOk.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.statusOk, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Товар принят в норме',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusOk,
                        fontSize: 14)),
                Text('Принято: $qtyOrdered $unit',
                    style: const TextStyle(
                        color: AppColors.statusOk, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: color)),
      ],
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final String name;
  final String? sku;
  final String? barcode;
  final double qtyOrdered;
  final String unit;

  const _ProductInfoCard({
    required this.name,
    this.sku,
    this.barcode,
    required this.qtyOrdered,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      if (sku != null) ...[
                        const SizedBox(height: 3),
                        _Tag(label: 'Арт: $sku'),
                      ],
                      if (barcode != null) ...[
                        const SizedBox(height: 3),
                        _Tag(label: 'ШК: $barcode'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Заказано:',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const Spacer(),
                Text(
                  '$qtyOrdered $unit',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
  }
}

class _StatusSelector extends StatelessWidget {
  final ScanStatus selected;
  final ValueChanged<ScanStatus> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (ScanStatus.ok, Icons.check_circle_rounded, AppColors.statusOk, 'Норма'),
      (ScanStatus.defect, Icons.broken_image_rounded, AppColors.statusDefect, 'Брак'),
      (ScanStatus.shortage, Icons.remove_circle_rounded, AppColors.statusShortage, 'Недостача'),
      (ScanStatus.surplus, Icons.add_circle_rounded, AppColors.statusSurplus, 'Излишек'),
    ];

    return Row(
      children: statuses.map((entry) {
        final (status, icon, color, label) = entry;
        final isSelected = selected == status;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: isSelected ? Colors.white : color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final Color color;
  final String hint;

  const _PhotoPicker({
    required this.photoPath,
    required this.onPick,
    required this.onRemove,
    required this.color,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photoPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(alpha: 0.3), style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded, color: color, size: 32),
              const SizedBox(height: 8),
              Text(hint,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
