import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_parser.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:universal_io/io.dart';

/// Reads a receipt photo with on-device OCR and parses it into a
/// [ReceiptScanModel].
///
/// This lives in the app layer rather than `core` on purpose: ML Kit ships
/// Android and iOS implementations only, while `core` is also compiled for the
/// web build. The parsing rules it delegates to live in `core` and stay
/// platform neutral.
class ReceiptScanRepository {
  final ReceiptParser _parser;

  /// Recognisers are expensive to build, so one is kept for the app's lifetime
  /// and reused across scans.
  TextRecognizer? _recognizer;

  ReceiptScanRepository({ReceiptParser parser = const ReceiptParser()})
      : _parser = parser;

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

      final lines = _toOcrLines(recognized);
      final scored = lines.where((line) => line.confidence != null).toList();
      log.stage(
          'OCR', '${lines.length} lines in ${recognized.blocks.length} blocks');
      if (scored.isNotEmpty) {
        final average =
            scored.fold(0.0, (sum, line) => sum + line.confidence!) /
                scored.length;
        log.detail('average confidence ${(average * 100).round()}%');
      }

      return ResourceUtil.success(_parser.parseLines(lines, log: log));
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  /// Maps ML Kit's result onto the plugin-free model the parser works with.
  ///
  /// Reading `recognized.text` instead would flatten the page into one string
  /// and throw away every coordinate, which is exactly what stops a label being
  /// matched to the amount printed opposite it.
  List<ReceiptOcrLine> _toOcrLines(RecognizedText recognized) {
    return [
      for (final block in recognized.blocks)
        for (final line in block.lines)
          ReceiptOcrLine(
            text: line.text,
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            right: line.boundingBox.right,
            bottom: line.boundingBox.bottom,
            confidence: line.confidence,
          ),
    ];
  }

  Future<void> close() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
