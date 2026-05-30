import 'package:dio/dio.dart';
import '../models/scan_result_model.dart';
import '../repositories/session_repository.dart';

class RealSessionRepository implements SessionRepository {
  RealSessionRepository(this._dio);
  final Dio _dio;

  // Хранит acceptance_id для текущей сессии (order_id -> acc_id)
  final Map<String, String> _acceptanceIds = {};

  Future<String> _getOrCreateAcceptance(String orderId) async {
    if (_acceptanceIds.containsKey(orderId)) {
      return _acceptanceIds[orderId]!;
    }
    final resp = await _dio.post('/orders/$orderId/acceptance');
    final accId = resp.data['id'] as String;
    _acceptanceIds[orderId] = accId;
    return accId;
  }

  @override
  Future<void> saveSession(String orderId, List<ScanRecord> records) async {
    try {
      final accId = await _getOrCreateAcceptance(orderId);

      // Отправляем расхождения по каждой записи (кроме норма)
      for (final record in records) {
        if (record.status == ScanStatus.ok) continue;

        await _dio.post('/acceptance/$accId/discrepancies', data: {
          'type': record.status.apiValue,
          if (record.status == ScanStatus.defect)
            'qty_defect': record.qtyDiscrepancy ?? 0,
          if (record.status == ScanStatus.shortage ||
              record.status == ScanStatus.surplus)
            'qty_actual': record.qtyActual,
          if (record.defectPhotoPath != null || record.scanPhotoUrl != null)
            'photo_url': record.scanPhotoUrl ?? record.defectPhotoPath,
          if (record.product.id.isNotEmpty) 'product_id': record.product.id,
        });
      }

      // Подтверждаем приёмку
      await _dio.post('/acceptance/$accId/accept');
      _acceptanceIds.remove(orderId);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Ошибка сохранения сессии');
    }
  }

  @override
  Future<String> uploadPhoto(
      String localPath, String recordId, String type) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          localPath,
          filename: '${type}_$recordId.jpg',
        ),
      });
      final resp = await _dio.post(
        '/products/recognize-image',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      // Возвращаем recognized_name как подсказку, URL не возвращается — используем путь
      final name = resp.data['recognized_name'] as String? ?? '';
      return name.isEmpty ? localPath : name;
    } on DioException catch (_) {
      return localPath;
    }
  }

  /// Загружает фото брака и получает count с сервера
  Future<Map<String, dynamic>> recognizeImage(String localPath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localPath, filename: 'defect.jpg'),
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
