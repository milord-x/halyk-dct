import 'product_model.dart';

enum ScanStatus { ok, defect, shortage, surplus }

extension ScanStatusExt on ScanStatus {
  String get label => switch (this) {
        ScanStatus.ok => 'Норма',
        ScanStatus.defect => 'Брак',
        ScanStatus.shortage => 'Недостача',
        ScanStatus.surplus => 'Излишек',
      };

  String get apiValue => switch (this) {
        ScanStatus.ok => 'ok',
        ScanStatus.defect => 'defect',
        ScanStatus.shortage => 'shortage',
        ScanStatus.surplus => 'surplus',
      };
}

class ScanRecord {
  final String id;
  final String orderId;
  final Product product;
  final ScanStatus status;
  final double qtyOrdered;
  final double qtyActual;
  final double? qtyDiscrepancy;
  final String? scanPhotoPath;     // фото товара при сканировании
  final String? defectPhotoPath;   // фото брака
  final String? scanPhotoUrl;      // URL после загрузки на сервер
  final DateTime scannedAt;

  const ScanRecord({
    required this.id,
    required this.orderId,
    required this.product,
    required this.status,
    required this.qtyOrdered,
    required this.qtyActual,
    this.qtyDiscrepancy,
    this.scanPhotoPath,
    this.defectPhotoPath,
    this.scanPhotoUrl,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_id': orderId,
        'product_id': product.id,
        'status': status.apiValue,
        'qty_ordered': qtyOrdered,
        'qty_actual': qtyActual,
        'qty_discrepancy': qtyDiscrepancy,
        'scan_photo_url': scanPhotoUrl,
        'defect_photo_path': defectPhotoPath,
        'scanned_at': scannedAt.toIso8601String(),
      };
}
