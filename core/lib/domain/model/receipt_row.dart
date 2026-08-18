import 'package:core/domain/model/receipt_ocr_line.dart';

/// One printed row of a receipt, keeping where each fragment sat on the page.
///
/// The parser reads [text] like any other line, but can still ask [xOfCharIndex]
/// which column a character belongs to, which is what separates an item's name
/// from the amount printed opposite it.
class ReceiptRow {
  final String text;

  /// Character ranges of [text] paired with the horizontal span they occupied,
  /// left to right. Empty when the row came from flattened text.
  final List<ReceiptRowSpan> spans;

  const ReceiptRow(this.text, {this.spans = const []});

  /// Builds a row from the fragments an OCR engine reported on one band.
  factory ReceiptRow.fromLines(List<ReceiptOcrLine> lines) {
    final buffer = StringBuffer();
    final spans = <ReceiptRowSpan>[];

    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;

      if (buffer.isNotEmpty) buffer.write(' ');
      final start = buffer.length;
      buffer.write(text);

      spans.add(ReceiptRowSpan(
        start: start,
        end: buffer.length,
        left: line.left,
        right: line.right,
      ));
    }

    return ReceiptRow(buffer.toString(), spans: spans);
  }

  bool get hasGeometry => spans.isNotEmpty;

  double get right => spans.isEmpty
      ? 0
      : spans.map((span) => span.right).reduce((a, b) => a > b ? a : b);

  /// Where the character at [index] sat horizontally, interpolated inside its
  /// fragment. Null when the row has no geometry.
  double? xOfCharIndex(int index) {
    for (final span in spans) {
      if (index > span.end) continue;

      final length = span.end - span.start;
      if (length <= 0) return span.left;

      final offset = ((index - span.start) / length).clamp(0.0, 1.0);
      return span.left + (span.right - span.left) * offset;
    }

    return spans.isEmpty ? null : spans.last.right;
  }
}

/// A fragment's slice of [ReceiptRow.text] and the pixels it covered.
class ReceiptRowSpan {
  final int start;
  final int end;
  final double left;
  final double right;

  const ReceiptRowSpan({
    required this.start,
    required this.end,
    required this.left,
    required this.right,
  });
}
