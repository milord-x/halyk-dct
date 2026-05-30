import 'package:dio/dio.dart';
import '../models/invoice_model.dart';

class RealInvoiceRepository {
  RealInvoiceRepository(this._dio);
  final Dio _dio;

  Future<Invoice> uploadInvoice(String orderId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'invoice.jpg'),
      });
      final resp = await _dio.post(
        '/orders/$orderId/invoice/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return Invoice.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Ошибка загрузки накладной';
      throw Exception(msg);
    }
  }

  Future<Invoice> getInvoice(String invoiceId) async {
    final resp = await _dio.get('/invoices/$invoiceId');
    return Invoice.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<InvoiceItemCheck>> checkInvoice(String invoiceId) async {
    try {
      final resp = await _dio.get('/invoices/$invoiceId/check');
      final data = resp.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => InvoiceItemCheck.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Invoice> patchItem(
      String itemId, {double? qty, double? price}) async {
    final body = <String, dynamic>{};
    if (qty != null) body['qty'] = qty;
    if (price != null) body['price'] = price;
    final resp = await _dio.patch('/invoice-items/$itemId', data: body);
    return Invoice.fromJson(resp.data as Map<String, dynamic>);
  }
}
