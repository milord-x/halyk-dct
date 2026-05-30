import '../models/scan_result_model.dart';
import '../repositories/session_repository.dart';

class MockSessionRepository implements SessionRepository {
  @override
  Future<void> saveSession(String orderId, List<ScanRecord> records) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // ignore: avoid_print
    print('[MockSessionRepository] Сохранена сессия $orderId: ${records.length} записей');
  }

  @override
  Future<String> uploadPhoto(String localPath, String recordId, String type) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return 'https://mock-storage.halyk.kz/$type/$recordId.jpg';
  }
}
