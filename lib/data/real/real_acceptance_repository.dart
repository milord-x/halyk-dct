import 'package:dio/dio.dart';
import '../models/acceptance_model.dart';

class RealAcceptanceRepository {
  RealAcceptanceRepository(this._dio);
  final Dio _dio;

  Future<AcceptanceSession> startAcceptance(String orderId) async {
    try {
      final resp = await _dio.post('/orders/$orderId/acceptance');
      return AcceptanceSession.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail'] ?? 'Ошибка открытия приёмки');
    }
  }

  Future<Map<String, dynamic>> addDiscrepancy(
    String accId, {
    required String type,
    String? invoiceItemId,
    String? productId,
    double? qtyActual,
    double? qtyDefect,
    String? photoUrl,
    String? comment,
  }) async {
    final body = <String, dynamic>{'type': type};
    if (invoiceItemId != null) body['invoice_item_id'] = invoiceItemId;
    if (productId != null) body['product_id'] = productId;
    if (qtyActual != null) body['qty_actual'] = qtyActual;
    if (qtyDefect != null) body['qty_defect'] = qtyDefect;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (comment != null) body['comment'] = comment;

    try {
      final resp =
          await _dio.post('/acceptance/$accId/discrepancies', data: body);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail'] ?? 'Ошибка добавления расхождения');
    }
  }

  Future<Map<String, dynamic>> createAct(String accId) async {
    try {
      final resp = await _dio.post('/acceptance/$accId/act');
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Ошибка создания акта');
    }
  }

  Future<void> confirmAcceptance(String accId) async {
    try {
      await _dio.post('/acceptance/$accId/accept');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?['detail'] ?? 'Ошибка подтверждения приёмки');
    }
  }

  Future<Map<String, dynamic>> recognizeImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file':
            await MultipartFile.fromFile(filePath, filename: 'defect.jpg'),
      });
      final resp = await _dio.post(
        '/products/recognize-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (_) {
      return {};
    }
  }
}
