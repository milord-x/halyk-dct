import '../models/scan_result_model.dart';

abstract class SessionRepository {
  Future<void> saveSession(String orderId, List<ScanRecord> records);
  Future<String> uploadPhoto(String localPath, String recordId, String type);
}
