import '../models/order_model.dart';
import '../models/product_model.dart';
import '../repositories/order_repository.dart';
import 'mock_data.dart';

class MockOrderRepository implements OrderRepository {
  @override
  Future<List<Order>> getOrdersForStore(String storeOrgId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return mockOrders.where((o) => o.storeOrgId == storeOrgId).toList();
  }

  @override
  Future<Order> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockOrders.firstWhere((o) => o.id == orderId);
  }

  @override
  Future<Product?> getProductByBarcode(String barcode, String orgId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return mockProducts.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
}
