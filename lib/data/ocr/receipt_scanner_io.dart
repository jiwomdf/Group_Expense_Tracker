import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_parser.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:group_expense_tracker/data/ocr/mlkit_ocr_lines.dart';
import 'package:group_expense_tracker/data/ocr/ocr_log_summary.dart';
import 'package:universal_io/io.dart';

/// Android and iOS receipt scanner, backed by on-device ML Kit.
///
/// Selected by the conditional export in `receipt_scanner.dart`; the web build
/// gets the Tesseract.js implementation instead. Both hand their lines to the
/// same platform-neutral parser in `core`.
class ReceiptScanner {
  final ReceiptParser _parser;

  /// Recognisers are expensive to build, so one is kept for the page's lifetime
  /// and reused across scans.
  TextRecognizer? _recognizer;

  ReceiptScanner({ReceiptParser parser = const ReceiptParser()})
      : _parser = parser;

  /// [imagePath] is a file path from `image_picker`.
  Future<ResourceUtil<ReceiptScanModel>> scan(String imagePath) async {
    final log = ReceiptScanLog();

    try {
      final recognizer =
          _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

      final bytes = await File(imagePath).length();
      log.stage('Image', '${(bytes / 1024).round()} KB');
      log.detail(imagePath.split('/').last);

      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));

      if (recognized.text.trim().isEmpty) {
        return ResourceUtil.error(const GeneralFailure(
            "No text found on the photo. Try again with better lighting and the whole receipt in frame."));
      }

      final lines = MlKitOcrLines.from(recognized);
      OcrLogSummary.write(log, lines,
          detail: 'ML Kit, ${recognized.blocks.length} blocks');

      return ResourceUtil.success(_parser.parseLines(lines, log: log));
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<void> close() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
