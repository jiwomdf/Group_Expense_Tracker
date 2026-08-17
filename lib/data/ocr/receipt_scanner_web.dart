import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_parser.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:group_expense_tracker/data/ocr/ocr_log_summary.dart';
import 'package:group_expense_tracker/data/ocr/tesseract_js.dart';
import 'package:group_expense_tracker/data/ocr/tesseract_ocr_lines.dart';

/// Web receipt scanner, backed by the self-hosted Tesseract.js in
/// `web/tesseract/`.
///
/// ML Kit has no web implementation, so the browser needs its own engine.
/// Tesseract reports a bounding box per line just as ML Kit does, so the
/// geometry-aware path works here too.
///
/// Accuracy is the trade-off: Tesseract is noticeably weaker than ML Kit on
/// thermal receipt fonts, so expect a web scan to need more correcting.
class ReceiptScanner {
  final ReceiptParser _parser;

  ReceiptScanner({ReceiptParser parser = const ReceiptParser()})
      : _parser = parser;

  /// [imageSource] is whatever `image_picker` handed back on web: a `blob:` URL
  /// that Tesseract.js can load directly.
  Future<ResourceUtil<ReceiptScanModel>> scan(String imageSource) async {
    final log = ReceiptScanLog();

    if (!TesseractJs.isLoaded) {
      return ResourceUtil.error(const GeneralFailure(
          "The text recogniser did not load. Reload the page and try again."));
    }

    try {
      log.stage('Image', 'uploaded file');

      final result = await TesseractJs.recognize(imageSource);
      final data = TesseractOcrLines.dataOf(result);
      if (data == null) {
        return ResourceUtil.error(
            const GeneralFailure("The text recogniser returned nothing."));
      }

      final rawText = TesseractOcrLines.textOf(data);
      if (rawText.trim().isEmpty) {
        return ResourceUtil.error(const GeneralFailure(
            "No text found on the image. Try a sharper photo with the whole receipt in frame."));
      }

      final lines = TesseractOcrLines.from(data);

      if (lines.isEmpty) {
        // Some builds omit per-line boxes. The parser still works without them,
        // just without column pairing.
        log.stage('OCR', 'text only, no line boxes reported');
        return ResourceUtil.success(_parser.parse(rawText, log: log));
      }

      OcrLogSummary.write(log, lines, detail: 'Tesseract.js, self-hosted');

      return ResourceUtil.success(_parser.parseLines(lines, log: log));
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<void> close() async {}
}
