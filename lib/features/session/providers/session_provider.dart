import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/scan_result_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/repository_providers.dart';

class SessionState {
  final Order? activeOrder;
  final List<ScanRecord> records;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const SessionState({
    this.activeOrder,
    this.records = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  SessionState copyWith({
    Order? activeOrder,
    List<ScanRecord>? records,
    bool? isSaving,
    bool? isSaved,
    String? error,
    bool clearError = false,
  }) =>
      SessionState(
        activeOrder: activeOrder ?? this.activeOrder,
        records: records ?? this.records,
        isSaving: isSaving ?? this.isSaving,
        isSaved: isSaved ?? this.isSaved,
        error: clearError ? null : (error ?? this.error),
      );
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._ref) : super(const SessionState());

  final Ref _ref;
  final _uuid = const Uuid();

  void startSession(Order order) {
    state = SessionState(activeOrder: order);
  }

  void addRecord({
    required Product product,
    required ScanStatus status,
    required double qtyOrdered,
    required double qtyActual,
    double? qtyDiscrepancy,
    String? defectPhotoPath,
  }) {
    final record = ScanRecord(
      id: _uuid.v4(),
      orderId: state.activeOrder!.id,
      product: product,
      status: status,
      qtyOrdered: qtyOrdered,
      qtyActual: qtyActual,
      qtyDiscrepancy: qtyDiscrepancy,
      defectPhotoPath: defectPhotoPath,
      scannedAt: DateTime.now(),
    );
    state = state.copyWith(records: [...state.records, record]);
  }

  void removeRecord(String recordId) {
    state = state.copyWith(
      records: state.records.where((r) => r.id != recordId).toList(),
    );
  }

  Future<void> saveSession() async {
    if (state.activeOrder == null) return;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repo = _ref.read(sessionRepositoryProvider);
      await repo.saveSession(state.activeOrder!.id, state.records);
      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = const SessionState();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
