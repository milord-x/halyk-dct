import '../models/order_model.dart';
import '../models/product_model.dart';

abstract class OrderRepository {
  Future<List<Order>> getOrdersForStore(String storeOrgId);
  Future<Order> getOrderById(String orderId);
  Future<Product?> getProductByBarcode(String barcode, String orgId);
}
