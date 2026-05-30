class InvoiceItem {
  final String id;
  final String name;
  final String? barcode;
  final double qty;
  final String unit;
  final double price;
  final double lineTotal;
  final double? confidence;
  final bool wasEdited;

  const InvoiceItem({
    required this.id,
    required this.name,
    this.barcode,
    required this.qty,
    this.unit = 'шт',
    required this.price,
    required this.lineTotal,
    this.confidence,
    this.wasEdited = false,
  });

  bool get isSuspicious => (confidence ?? 1.0) < 0.8;

  factory InvoiceItem.fromJson(Map<String, dynamic> j) => InvoiceItem(
        id: j['id'] as String,
        name: j['name'] as String,
        barcode: j['barcode'] as String?,
        qty: double.parse(j['qty'].toString()),
        unit: j['unit'] as String? ?? 'шт',
        price: double.parse(j['price'].toString()),
        lineTotal: double.parse(j['line_total'].toString()),
        confidence: j['confidence'] != null
            ? double.parse(j['confidence'].toString())
            : null,
        wasEdited: j['was_edited'] as bool? ?? false,
      );

  InvoiceItem copyWith({double? qty, double? price}) => InvoiceItem(
        id: id,
        name: name,
        barcode: barcode,
        qty: qty ?? this.qty,
        unit: unit,
        price: price ?? this.price,
        lineTotal: (qty ?? this.qty) * (price ?? this.price),
        confidence: confidence,
        wasEdited: true,
      );
}

class Invoice {
  final String id;
  final String orderId;
  final String? supplierName;
  final String? invoiceNumber;
  final String? invoiceDate;
  final double? totalSum;
  final String ocrStatus;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.orderId,
    this.supplierName,
    this.invoiceNumber,
    this.invoiceDate,
    this.totalSum,
    required this.ocrStatus,
    this.items = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: j['id'] as String,
        orderId: j['order_id'] as String,
        supplierName: j['supplier_name'] as String?,
        invoiceNumber: j['invoice_number'] as String?,
        invoiceDate: j['invoice_date'] as String?,
        totalSum: j['total_sum'] != null
            ? double.parse(j['total_sum'].toString())
            : null,
        ocrStatus: j['ocr_status'] as String,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class InvoiceItemCheck {
  final String invoiceItemId;
  final String name;
  final bool ok;
  final List<String> issues;

  const InvoiceItemCheck({
    required this.invoiceItemId,
    required this.name,
    required this.ok,
    this.issues = const [],
  });

  factory InvoiceItemCheck.fromJson(Map<String, dynamic> j) => InvoiceItemCheck(
        invoiceItemId: j['invoice_item_id'] as String,
        name: j['name'] as String,
        ok: j['ok'] as bool,
        issues: (j['issues'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
