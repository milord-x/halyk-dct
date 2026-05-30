import '../models/scan_result_model.dart';
import '../repositories/session_repository.dart';

class MockSessionRepository implements SessionRepository {
  @override
  Future<void> saveSession(String orderId, List<ScanRecord> records) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    // ignore: avoid_print
    print('[MockSessionRepository] Сохранена сессия для заявки $orderId: ${records.length} записей');
    for (final r in records) {
      // ignore: avoid_print
      print('  - ${r.product.name}: ${r.status.label}, факт=${r.qtyActual}');
    }
  }

  @override
  Future<String> uploadDefectPhoto(String localPath, String recordId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://mock-storage.halyk.kz/defects/$recordId.jpg';
  }
}
