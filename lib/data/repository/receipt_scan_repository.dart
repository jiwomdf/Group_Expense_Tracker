import 'package:core/domain/model/failure.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/receipt/receipt_parser.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
    try {
      final recognizer =
          _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

      final recognized =
          await recognizer.processImage(InputImage.fromFilePath(imagePath));

      if (recognized.text.trim().isEmpty) {
        return ResourceUtil.error(const GeneralFailure(
            "No text found on the photo. Try again with better lighting and the whole receipt in frame."));
      }

      return ResourceUtil.success(_parser.parse(recognized.text));
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<void> close() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
