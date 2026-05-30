import 'product_model.dart';

enum OrderStatus {
  newOrder,
  shipped,
  receiving,
  accepted,
  discrepancy,
  actCreated,
  invoiceCorrected,
  closed,
  cancelled;

  static OrderStatus fromString(String s) => switch (s) {
        'new' => newOrder,
        'shipped' => shipped,
        'receiving' => receiving,
        'accepted' => accepted,
        'discrepancy' => discrepancy,
        'act_created' => actCreated,
        'invoice_corrected' => invoiceCorrected,
        'closed' => closed,
        'cancelled' => cancelled,
        _ => newOrder,
      };

  String get label => switch (this) {
        newOrder => 'Новая',
        shipped => 'Отгружена',
        receiving => 'Приёмка',
        accepted => 'Принята',
        discrepancy => 'Расхождение',
        actCreated => 'Акт создан',
        invoiceCorrected => 'Накл. скорр.',
        closed => 'Закрыта',
        cancelled => 'Отменена',
      };
}

class OrderItem {
  final String id;
  final String orderId;
  final Product? product;
  final String name;
  final double qtyOrdered;
  final double? price;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.product,
    required this.name,
    required this.qtyOrdered,
    this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        product: json['product'] != null
            ? Product.fromJson(json['product'] as Map<String, dynamic>)
            : null,
        name: json['name'] as String,
        qtyOrdered: (json['qty_ordered'] as num).toDouble(),
        price: (json['price'] as num?)?.toDouble(),
      );
}

class Order {
  final String id;
  final String storeOrgId;
  final String supplierOrgId;
  final String supplierName;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.storeOrgId,
    required this.supplierOrgId,
    required this.supplierName,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        storeOrgId: json['store_org_id'] as String,
        supplierOrgId: json['supplier_org_id'] as String,
        supplierName: json['supplier_name'] as String? ?? '',
        status: OrderStatus.fromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
