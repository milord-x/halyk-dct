import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../providers/invoice_provider.dart';

class InvoiceCameraScreen extends ConsumerStatefulWidget {
  final String orderId;
  const InvoiceCameraScreen({super.key, required this.orderId});

  @override
  ConsumerState<InvoiceCameraScreen> createState() =>
      _InvoiceCameraScreenState();
}

class _InvoiceCameraScreenState extends ConsumerState<InvoiceCameraScreen> {
  String? _pickedPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.read(invoiceProvider.notifier).reset();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _pickedPath = picked.path);
  }

  Future<void> _upload() async {
    if (_pickedPath == null) return;
    setState(() => _isLoading = true);
    await ref
        .read(invoiceProvider.notifier)
        .upload(widget.orderId, _pickedPath!);
    if (!mounted) return;
    setState(() => _isLoading = false);
    final state = ref.read(invoiceProvider);
    if (state.invoice != null) {
      context.push('/orders/${widget.orderId}/invoice-review');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceProvider);

    return Scaffold(
      appBar: const HalykAppBar(title: 'Накладная'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Иллюстрация/превью
            Expanded(
              child: _pickedPath == null
                  ? _PlaceholderBox()
                  : _PreviewBox(path: _pickedPath!),
            ),
            const SizedBox(height: 24),

            if (state.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(state.error!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Кнопки выбора
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Камера'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Галерея'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: (_pickedPath == null || _isLoading) ? null : _upload,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_isLoading ? 'ИИ распознаёт...' : 'Распознать накладную'),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 12),
              Text(
                'Это может занять 15–30 секунд',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 80, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Сфотографируйте накладную\nили выберите из галереи',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final String path;
  const _PreviewBox({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
      ),
    );
  }
}
