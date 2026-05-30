import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/invoice_providers.dart';

class InvoiceState {
  final bool isUploading;
  final Invoice? invoice;
  final String? error;

  const InvoiceState({
    this.isUploading = false,
    this.invoice,
    this.error,
  });

  InvoiceState copyWith({
    bool? isUploading,
    Invoice? invoice,
    String? error,
    bool clearError = false,
  }) =>
      InvoiceState(
        isUploading: isUploading ?? this.isUploading,
        invoice: invoice ?? this.invoice,
        error: clearError ? null : (error ?? this.error),
      );
}

class InvoiceNotifier extends StateNotifier<InvoiceState> {
  InvoiceNotifier(this._ref) : super(const InvoiceState());
  final Ref _ref;

  Future<void> upload(String orderId, String filePath) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final invoice =
          await _ref.read(invoiceRepoProvider).uploadInvoice(orderId, filePath);
      state = state.copyWith(isUploading: false, invoice: invoice);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> patchItem(String itemId,
      {double? qty, double? price}) async {
    try {
      final updated = await _ref
          .read(invoiceRepoProvider)
          .patchItem(itemId, qty: qty, price: price);
      state = state.copyWith(invoice: updated);
    } catch (e) {
      state = state.copyWith(
          error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void reset() => state = const InvoiceState();
}

final invoiceProvider =
    StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  return InvoiceNotifier(ref);
});
