class Discrepancy {
  final String id;
  final String type;
  final double? qtyExpected;
  final double? qtyActual;
  final double? qtyDefect;
  final double? price;
  final double amountDelta;
  final String? photoUrl;
  final String? comment;

  const Discrepancy({
    required this.id,
    required this.type,
    this.qtyExpected,
    this.qtyActual,
    this.qtyDefect,
    this.price,
    required this.amountDelta,
    this.photoUrl,
    this.comment,
  });

  factory Discrepancy.fromJson(Map<String, dynamic> j) => Discrepancy(
        id: j['id'] as String,
        type: j['type'] as String,
        qtyExpected: j['qty_expected'] != null
            ? double.parse(j['qty_expected'].toString())
            : null,
        qtyActual: j['qty_actual'] != null
            ? double.parse(j['qty_actual'].toString())
            : null,
        qtyDefect: j['qty_defect'] != null
            ? double.parse(j['qty_defect'].toString())
            : null,
        price: j['price'] != null
            ? double.parse(j['price'].toString())
            : null,
        amountDelta: double.parse(j['amount_delta'].toString()),
        photoUrl: j['photo_url'] as String?,
        comment: j['comment'] as String?,
      );
}

class AcceptanceSession {
  final String id;
  final String orderId;
  final String invoiceId;
  final String status;
  final List<Discrepancy> discrepancies;
  final double? originalSum;
  final double? correctedSum;
  final double? totalDelta;

  const AcceptanceSession({
    required this.id,
    required this.orderId,
    required this.invoiceId,
    required this.status,
    this.discrepancies = const [],
    this.originalSum,
    this.correctedSum,
    this.totalDelta,
  });

  factory AcceptanceSession.fromJson(Map<String, dynamic> j) =>
      AcceptanceSession(
        id: j['id'] as String,
        orderId: j['order_id'] as String,
        invoiceId: j['invoice_id'] as String,
        status: j['status'] as String,
        discrepancies: (j['discrepancies'] as List<dynamic>? ?? [])
            .map((e) => Discrepancy.fromJson(e as Map<String, dynamic>))
            .toList(),
        originalSum: j['original_sum'] != null
            ? double.parse(j['original_sum'].toString())
            : null,
        correctedSum: j['corrected_sum'] != null
            ? double.parse(j['corrected_sum'].toString())
            : null,
        totalDelta: j['total_delta'] != null
            ? double.parse(j['total_delta'].toString())
            : null,
      );
}
