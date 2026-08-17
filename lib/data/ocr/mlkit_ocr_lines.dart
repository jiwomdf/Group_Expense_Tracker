import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reads ML Kit's result into the parser's plugin-free model.
class MlKitOcrLines {
  const MlKitOcrLines._();

  /// Walks blocks then lines, keeping each line's box and confidence.
  ///
  /// Reading `recognized.text` instead would flatten the page into one string
  /// and throw away every coordinate, which is exactly what stops a label being
  /// matched to the amount printed opposite it.
  static List<ReceiptOcrLine> from(RecognizedText recognized) {
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
}
