import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/halyk_app_bar.dart';
import '../providers/scanner_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String orderId;
  const ScannerScreen({super.key, required this.orderId});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  MobileScannerController? _controller;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    ref.read(scannerProvider.notifier).reset();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;
    ref.read(scannerProvider.notifier).onBarcodeDetected(barcode);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScannerState>(scannerProvider, (_, next) {
      if (next.foundProduct != null && !next.isSearching) {
        context.push('/orders/${widget.orderId}/scan-result');
      }
    });

    final state = ref.watch(scannerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: HalykAppBar(
        title: 'Сканирование',
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller?.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),
          // Оверлей с прицелом
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Подсказка сверху
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Наведите камеру на штрих-код',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          // Статус поиска / ошибка снизу
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.isSearching
                  ? _StatusChip(
                      key: const ValueKey('loading'),
                      color: AppColors.primary,
                      icon: const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      label: 'Поиск товара...',
                    )
                  : state.error != null
                      ? _StatusChip(
                          key: const ValueKey('error'),
                          color: AppColors.error,
                          icon: const Icon(Icons.error_outline,
                              color: Colors.white, size: 16),
                          label: state.error!,
                          onTap: () =>
                              ref.read(scannerProvider.notifier).reset(),
                        )
                      : const SizedBox.shrink(key: ValueKey('idle')),
            ),
          ),
          // Кнопка сводки сессии
          Positioned(
            bottom: 48,
            right: 24,
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () =>
                  context.push('/orders/${widget.orderId}/summary'),
              icon: const Icon(Icons.checklist_rounded),
              label: const Text('Сводка'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _StatusChip({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Text('Сбросить',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        decoration: TextDecoration.underline)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.55);
    const frameW = 260.0;
    const frameH = 160.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
        center: Offset(cx, cy), width: frameW, height: frameH);

    canvas
      ..drawRect(
          Rect.fromLTWH(0, 0, size.width, rect.top), dark)
      ..drawRect(
          Rect.fromLTWH(0, rect.bottom, size.width, size.height - rect.bottom),
          dark)
      ..drawRect(Rect.fromLTWH(0, rect.top, rect.left, frameH), dark)
      ..drawRect(
          Rect.fromLTWH(rect.right, rect.top, size.width - rect.right, frameH),
          dark);

    final corner = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const r = 12.0;
    const len = 28.0;
    // top-left
    canvas
      ..drawLine(rect.topLeft + const Offset(r, 0),
          rect.topLeft + const Offset(len, 0), corner)
      ..drawLine(rect.topLeft + const Offset(0, r),
          rect.topLeft + const Offset(0, len), corner)
      // top-right
      ..drawLine(rect.topRight - const Offset(len, 0),
          rect.topRight - const Offset(r, 0), corner)
      ..drawLine(rect.topRight + const Offset(0, r),
          rect.topRight + const Offset(0, len), corner)
      // bottom-left
      ..drawLine(rect.bottomLeft + const Offset(r, 0),
          rect.bottomLeft + const Offset(len, 0), corner)
      ..drawLine(rect.bottomLeft - const Offset(0, len),
          rect.bottomLeft - const Offset(0, r), corner)
      // bottom-right
      ..drawLine(rect.bottomRight - const Offset(len, 0),
          rect.bottomRight - const Offset(r, 0), corner)
      ..drawLine(rect.bottomRight - const Offset(0, len),
          rect.bottomRight - const Offset(0, r), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
