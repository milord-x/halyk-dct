import '../models/product_model.dart';
import '../models/order_model.dart';

const _orgStore1 = 'org-store-001';
const _orgStore2 = 'org-store-002';
const _orgSupplier = 'org-supplier-001';

final mockProducts = [
  Product(id: 'prod-001', organizationId: _orgSupplier, sku: 'SKU-1001', barcode: '4600149100038', name: 'Молоко Простоквашино 3.2% 1л', unit: 'шт'),
  Product(id: 'prod-002', organizationId: _orgSupplier, sku: 'SKU-1002', barcode: '4607123400012', name: 'Хлеб Белый нарезной 500г', unit: 'шт'),
  Product(id: 'prod-003', organizationId: _orgSupplier, sku: 'SKU-1003', barcode: '4605246002133', name: 'Масло Сливочное 82.5% 200г', unit: 'шт'),
  Product(id: 'prod-004', organizationId: _orgSupplier, sku: 'SKU-1004', barcode: '8690624020354', name: 'Вода Bonaqua 1.5л', unit: 'шт'),
  Product(id: 'prod-005', organizationId: _orgSupplier, sku: 'SKU-1005', barcode: '4605246001891', name: 'Сахар-песок 1кг', unit: 'кг'),
  Product(id: 'prod-006', organizationId: _orgSupplier, sku: 'SKU-1006', barcode: '4607029070019', name: 'Яйцо куриное С1 10шт', unit: 'упак'),
  Product(id: 'prod-007', organizationId: _orgSupplier, sku: 'SKU-1007', barcode: '4600951010313', name: 'Кефир Danone 2.5% 900г', unit: 'шт'),
  Product(id: 'prod-008', organizationId: _orgSupplier, sku: 'SKU-1008', barcode: '4607051460331', name: 'Гречка ядрица 800г', unit: 'шт'),
];

final mockOrders = [
  Order(
    id: 'order-001',
    storeOrgId: _orgStore1,
    supplierOrgId: _orgSupplier,
    supplierName: 'ТОО "Halyk Дистрибьюция"',
    status: OrderStatus.shipped,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    items: [
      OrderItem(id: 'oi-001', orderId: 'order-001', product: mockProducts[0], name: mockProducts[0].name, qtyOrdered: 48, price: 220),
      OrderItem(id: 'oi-002', orderId: 'order-001', product: mockProducts[1], name: mockProducts[1].name, qtyOrdered: 30, price: 150),
      OrderItem(id: 'oi-003', orderId: 'order-001', product: mockProducts[2], name: mockProducts[2].name, qtyOrdered: 24, price: 380),
      OrderItem(id: 'oi-004', orderId: 'order-001', product: mockProducts[3], name: mockProducts[3].name, qtyOrdered: 60, price: 130),
      OrderItem(id: 'oi-005', orderId: 'order-001', product: mockProducts[4], name: mockProducts[4].name, qtyOrdered: 20, price: 200),
    ],
  ),
  Order(
    id: 'order-002',
    storeOrgId: _orgStore1,
    supplierOrgId: _orgSupplier,
    supplierName: 'ТОО "Halyk Дистрибьюция"',
    status: OrderStatus.newOrder,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    items: [
      OrderItem(id: 'oi-006', orderId: 'order-002', product: mockProducts[5], name: mockProducts[5].name, qtyOrdered: 15, price: 540),
      OrderItem(id: 'oi-007', orderId: 'order-002', product: mockProducts[6], name: mockProducts[6].name, qtyOrdered: 36, price: 190),
      OrderItem(id: 'oi-008', orderId: 'order-002', product: mockProducts[7], name: mockProducts[7].name, qtyOrdered: 24, price: 160),
    ],
  ),
  Order(
    id: 'order-003',
    storeOrgId: _orgStore2,
    supplierOrgId: _orgSupplier,
    supplierName: 'ТОО "Halyk Дистрибьюция"',
    status: OrderStatus.receiving,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    items: [
      OrderItem(id: 'oi-009', orderId: 'order-003', product: mockProducts[0], name: mockProducts[0].name, qtyOrdered: 24, price: 220),
      OrderItem(id: 'oi-010', orderId: 'order-003', product: mockProducts[3], name: mockProducts[3].name, qtyOrdered: 48, price: 130),
    ],
  ),
];
