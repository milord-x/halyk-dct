import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../repositories/order_repository.dart';

class RealOrderRepository implements OrderRepository {
  RealOrderRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<Order>> getOrdersForStore(String storeOrgId) async {
    try {
      final resp = await _dio.get('/orders');
      final list = resp.data as List<dynamic>;
      return list.map((e) => _parseOrder(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Ошибка загрузки заявок');
    }
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    try {
      final resp = await _dio.get('/orders/$orderId');
      return _parseOrder(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Заявка не найдена');
    }
  }

  @override
  Future<Product?> getProductByBarcode(String barcode, String orgId) async {
    try {
      final resp = await _dio.get('/products', queryParameters: {'barcode': barcode});
      final list = resp.data as List<dynamic>;
      if (list.isEmpty) return null;
      final p = list.first as Map<String, dynamic>;
      return Product(
        id: p['id'] as String,
        organizationId: orgId,
        sku: null,
        barcode: p['barcode'] as String?,
        name: p['name'] as String,
        unit: p['unit'] as String? ?? 'шт',
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Ошибка поиска товара');
    }
  }

  Order _parseOrder(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? []).map((e) {
      final item = e as Map<String, dynamic>;
      return OrderItem(
        id: item['id'] as String,
        orderId: json['id'] as String,
        name: item['name'] as String,
        qtyOrdered: double.parse(item['qty_ordered'].toString()),
        price: item['price'] != null
            ? double.parse(item['price'].toString())
            : null,
      );
    }).toList();

    return Order(
      id: json['id'] as String,
      storeOrgId: json['store_org_id'] as String,
      supplierOrgId: json['supplier_org_id'] as String,
      supplierName: json['supplier_name'] as String? ?? 'Поставщик',
      status: OrderStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: items,
    );
  }
}
