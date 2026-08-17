import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';

/// The OCR stage entries both engines write, so the process log reads the same
/// whichever one ran.
class OcrLogSummary {
  const OcrLogSummary._();

  /// [detail] names the engine's own units, e.g. how many blocks it used.
  static void write(
    ReceiptScanLog log,
    List<ReceiptOcrLine> lines, {
    String? detail,
  }) {
    log.stage('OCR', '${lines.length} lines');
    if (detail != null) log.detail(detail);

    final scored = lines.where((line) => line.confidence != null).toList();
    if (scored.isEmpty) return;

    // Both engines are normalised to 0-1 before reaching here.
    final average =
        scored.fold(0.0, (sum, line) => sum + line.confidence!) / scored.length;
    log.detail('average confidence ${(average * 100).round()}%');
  }
}
