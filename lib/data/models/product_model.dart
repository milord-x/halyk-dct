class Product {
  final String id;
  final String organizationId;
  final String? sku;
  final String? barcode;
  final String name;
  final String unit;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.organizationId,
    this.sku,
    this.barcode,
    required this.name,
    this.unit = 'шт',
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        sku: json['sku'] as String?,
        barcode: json['barcode'] as String?,
        name: json['name'] as String,
        unit: json['unit'] as String? ?? 'шт',
        imageUrl: json['image_url'] as String?,
      );
}
