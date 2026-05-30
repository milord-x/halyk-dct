import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/acceptance_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/invoice_providers.dart';

enum DiscType { ok, shortage, surplus, defect, misgrade }

extension DiscTypeExt on DiscType {
  String get apiValue => switch (this) {
        DiscType.ok => 'ok',
        DiscType.shortage => 'shortage',
        DiscType.surplus => 'surplus',
        DiscType.defect => 'defect',
        DiscType.misgrade => 'misgrade',
      };

  String get label => switch (this) {
        DiscType.ok => 'Норма',
        DiscType.shortage => 'Недостача',
        DiscType.surplus => 'Излишек',
        DiscType.defect => 'Брак',
        DiscType.misgrade => 'Пересорт',
      };
}

class ItemDiscrepancy {
  final InvoiceItem item;
  final DiscType type;
  final double? qtyActual;
  final double? qtyDefect;
  final String? photoUrl;

  const ItemDiscrepancy({
    required this.item,
    required this.type,
    this.qtyActual,
    this.qtyDefect,
    this.photoUrl,
  });
}

class AcceptanceState {
  final AcceptanceSession? session;
  final Map<String, ItemDiscrepancy> itemStatuses; // invoiceItemId -> status
  final bool isSaving;
  final bool isConfirmed;
  final double? originalSum;
  final double? correctedSum;
  final double? totalDelta;
  final String? error;

  const AcceptanceState({
    this.session,
    this.itemStatuses = const {},
    this.isSaving = false,
    this.isConfirmed = false,
    this.originalSum,
    this.correctedSum,
    this.totalDelta,
    this.error,
  });

  bool get hasDiscrepancies =>
      itemStatuses.values.any((d) => d.type != DiscType.ok);

  AcceptanceState copyWith({
    AcceptanceSession? session,
    Map<String, ItemDiscrepancy>? itemStatuses,
    bool? isSaving,
    bool? isConfirmed,
    double? originalSum,
    double? correctedSum,
    double? totalDelta,
    String? error,
    bool clearError = false,
  }) =>
      AcceptanceState(
        session: session ?? this.session,
        itemStatuses: itemStatuses ?? this.itemStatuses,
        isSaving: isSaving ?? this.isSaving,
        isConfirmed: isConfirmed ?? this.isConfirmed,
        originalSum: originalSum ?? this.originalSum,
        correctedSum: correctedSum ?? this.correctedSum,
        totalDelta: totalDelta ?? this.totalDelta,
        error: clearError ? null : (error ?? this.error),
      );
}

class AcceptanceNotifier extends StateNotifier<AcceptanceState> {
  AcceptanceNotifier(this._ref) : super(const AcceptanceState());
  final Ref _ref;

  Future<void> startAcceptance(String orderId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final session =
          await _ref.read(acceptanceRepoProvider).startAcceptance(orderId);
      state = state.copyWith(session: session, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setItemStatus(InvoiceItem item, DiscType type,
      {double? qtyActual, double? qtyDefect, String? photoUrl}) {
    final updated = Map<String, ItemDiscrepancy>.from(state.itemStatuses);
    if (type == DiscType.ok) {
      updated.remove(item.id);
    } else {
      updated[item.id] = ItemDiscrepancy(
        item: item,
        type: type,
        qtyActual: qtyActual,
        qtyDefect: qtyDefect,
        photoUrl: photoUrl,
      );
    }
    state = state.copyWith(itemStatuses: updated);
  }

  Future<Map<String, dynamic>> recognizeImage(String filePath) async {
    return _ref.read(acceptanceRepoProvider).recognizeImage(filePath);
  }

  Future<bool> saveAndFinish(List<InvoiceItem> allItems) async {
    final accId = state.session?.id;
    if (accId == null) return false;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repo = _ref.read(acceptanceRepoProvider);

      // Отправляем расхождения
      Map<String, dynamic>? lastResult;
      for (final disc in state.itemStatuses.values) {
        if (disc.type == DiscType.ok) continue;
        lastResult = await repo.addDiscrepancy(
          accId,
          type: disc.type.apiValue,
          invoiceItemId: disc.item.id,
          qtyActual: disc.qtyActual,
          qtyDefect: disc.qtyDefect,
          photoUrl: disc.photoUrl,
        );
      }

      // Если есть расхождения — создаём акт
      if (state.hasDiscrepancies && lastResult != null) {
        await repo.createAct(accId);
        state = state.copyWith(
          isSaving: false,
          originalSum: lastResult['original_sum'] != null
              ? double.parse(lastResult['original_sum'].toString())
              : null,
          correctedSum: lastResult['corrected_sum'] != null
              ? double.parse(lastResult['corrected_sum'].toString())
              : null,
          totalDelta: lastResult['total_delta'] != null
              ? double.parse(lastResult['total_delta'].toString())
              : null,
        );
        return true;
      }

      // Без расхождений — сразу подтверждаем
      await repo.confirmAcceptance(accId);
      state = state.copyWith(isSaving: false, isConfirmed: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> confirmAct() async {
    final accId = state.session?.id;
    if (accId == null) return;
    state = state.copyWith(isSaving: true);
    try {
      await _ref.read(acceptanceRepoProvider).confirmAcceptance(accId);
      state = state.copyWith(isSaving: false, isConfirmed: true);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const AcceptanceState();
}

final acceptanceProvider =
    StateNotifierProvider<AcceptanceNotifier, AcceptanceState>((ref) {
  return AcceptanceNotifier(ref);
});
