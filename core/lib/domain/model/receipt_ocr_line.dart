/// One line of text an OCR engine found, with where it sat on the page.
///
/// Deliberately plain Dart rather than an ML Kit type: the engine is mobile
/// only, but everything that reasons about layout stays testable and web safe.
/// The app layer maps `TextLine` onto this.
class ReceiptOcrLine {
  final String text;

  /// Bounding box in image pixels, y growing downwards.
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// How sure the engine was, when it says. Null on engines or versions that
  /// do not report it.
  final double? confidence;

  const ReceiptOcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.confidence,
  });

  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;

  /// How much of the shorter line's height the two share vertically, from 0
  /// (no overlap) to 1 (one sits entirely within the other's band).
  ///
  /// This is what decides whether `TOTAL` on the far left and `23.500` on the
  /// far right belong to the same printed row.
  double verticalOverlapWith(ReceiptOcrLine other) {
    final overlap = (bottom < other.bottom ? bottom : other.bottom) -
        (top > other.top ? top : other.top);
    if (overlap <= 0) return 0;

    final shorter = height < other.height ? height : other.height;
    if (shorter <= 0) return 0;

    return overlap / shorter;
  }
}
