import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

class ScannerState {
  final bool isSearching;
  final Product? foundProduct;
  final String? error;
  final String? lastBarcode;
  final String? scanPhotoPath;    // фото товара сделанное при сканировании
  final bool isUploadingPhoto;

  const ScannerState({
    this.isSearching = false,
    this.foundProduct,
    this.error,
    this.lastBarcode,
    this.scanPhotoPath,
    this.isUploadingPhoto = false,
  });

  ScannerState copyWith({
    bool? isSearching,
    Product? foundProduct,
    String? error,
    String? lastBarcode,
    String? scanPhotoPath,
    bool? isUploadingPhoto,
    bool clearProduct = false,
    bool clearError = false,
    bool clearPhoto = false,
  }) =>
      ScannerState(
        isSearching: isSearching ?? this.isSearching,
        foundProduct: clearProduct ? null : (foundProduct ?? this.foundProduct),
        error: clearError ? null : (error ?? this.error),
        lastBarcode: lastBarcode ?? this.lastBarcode,
        scanPhotoPath: clearPhoto ? null : (scanPhotoPath ?? this.scanPhotoPath),
        isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      );
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  ScannerNotifier(this._ref) : super(const ScannerState());

  final Ref _ref;

  Future<void> onBarcodeDetected(String barcode) async {
    if (state.isSearching || state.lastBarcode == barcode) return;
    state = state.copyWith(
        isSearching: true, clearProduct: true, clearError: true, lastBarcode: barcode);

    final user = _ref.read(authProvider).user;
    if (user == null) {
      state = state.copyWith(isSearching: false, error: 'Не авторизован');
      return;
    }

    try {
      final product = await _ref
          .read(orderRepositoryProvider)
          .getProductByBarcode(barcode, user.organizationId);

      if (product == null) {
        state = state.copyWith(
            isSearching: false, error: 'Товар не найден: $barcode');
      } else {
        state = state.copyWith(isSearching: false, foundProduct: product);
      }
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: 'Ошибка поиска: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void setScanPhoto(String path) {
    state = state.copyWith(scanPhotoPath: path);
  }

  void reset() {
    state = const ScannerState();
  }
}

final scannerProvider =
    StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  return ScannerNotifier(ref);
});
