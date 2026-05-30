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
  final bool _isSaving = false;

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
    if (picked != null) {
      setState(() => _defectPhotoPath = picked.path);
    }
  }

  void _submit() {
    final product = ref.read(scannerProvider).foundProduct!;
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
          defectPhotoPath: _defectPhotoPath,
        );

    ref.read(scannerProvider.notifier).reset();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(scannerProvider).foundProduct;
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

    return Scaffold(
      appBar: const HalykAppBar(title: 'Результат сканирования'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProductInfoCard(
            name: product.name,
            sku: product.sku,
            barcode: product.barcode,
            qtyOrdered: orderItem?.qtyOrdered ?? 0,
            unit: product.unit,
          ),
          const SizedBox(height: 20),
          const Text(
            'Выберите статус товара',
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildExtraFields(context, orderItem?.qtyOrdered ?? 0, product.unit),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _submit,
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
        ],
      ),
    );
  }

  Widget _buildExtraFields(BuildContext context, double qtyOrdered, String unit) {
    switch (_selectedStatus) {
      case ScanStatus.ok:
        return const SizedBox.shrink(key: ValueKey('ok'));

      case ScanStatus.defect:
        return Column(
          key: const ValueKey('defect'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Количество брака',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _defectQtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Кол-во бракованных единиц',
                suffixText: unit,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Фото брака',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            _PhotoPicker(
              photoPath: _defectPhotoPath,
              onPick: _pickDefectPhoto,
              onRemove: () => setState(() => _defectPhotoPath = null),
            ),
          ],
        );

      case ScanStatus.shortage:
        return Column(
          key: const ValueKey('shortage'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сколько не хватает',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Количество недостающих единиц',
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
            const Text('Сколько лишнего',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Количество лишних единиц',
                suffixText: unit,
                helperText: 'Заказано: $qtyOrdered $unit',
              ),
            ),
          ],
        );
    }
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
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
                    const SizedBox(height: 2),
                    Text('Арт: $sku',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                  if (barcode != null) ...[
                    const SizedBox(height: 2),
                    Text('ШК: $barcode',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Заказано: $qtyOrdered $unit',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final ScanStatus selected;
  final ValueChanged<ScanStatus> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (ScanStatus.ok, Icons.check_circle_rounded, AppColors.statusOk),
      (ScanStatus.defect, Icons.broken_image_rounded, AppColors.statusDefect),
      (ScanStatus.shortage, Icons.remove_circle_rounded, AppColors.statusShortage),
      (ScanStatus.surplus, Icons.add_circle_rounded, AppColors.statusSurplus),
    ];

    return Row(
      children: statuses.map((entry) {
        final (status, icon, color) = entry;
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
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: isSelected ? Colors.white : color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    status.label,
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

  const _PhotoPicker({
    required this.photoPath,
    required this.onPick,
    required this.onRemove,
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
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
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
          color: AppColors.statusDefect.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.statusDefect.withValues(alpha: 0.3),
              style: BorderStyle.solid),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: AppColors.statusDefect, size: 32),
              SizedBox(height: 8),
              Text('Сделать фото брака',
                  style: TextStyle(
                      color: AppColors.statusDefect, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
