import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/domain/model/receipt_row.dart';

/// Rebuilds the receipt's printed rows from positioned OCR lines.
///
/// OCR engines emit text in blocks, and on a two-column layout a label and its
/// amount land in different blocks — flattening to a string puts `TOTAL` and
/// `23.500` far apart, or leaves an amount stranded with no description. Lines
/// that share a horizontal band are one printed row no matter which block they
/// came from, so grouping by vertical overlap restores the receipt as read by
/// eye, and every existing text rule then works unchanged.
class ReceiptLineGrouper {
  /// Fraction of the shorter line's height two lines must share to count as the
  /// same row. Generous enough for the baseline wobble of a hand-held photo,
  /// tight enough not to swallow the row above or below.
  final double overlapThreshold;

  const ReceiptLineGrouper({this.overlapThreshold = 0.5});

  /// Returns one row per printed line, top to bottom, each row's fragments
  /// joined left to right and keeping their horizontal spans.
  List<ReceiptRow> groupRows(List<ReceiptOcrLine> lines) {
    final ordered = [...lines]..sort((a, b) => a.centerY.compareTo(b.centerY));
    final rows = <List<ReceiptOcrLine>>[];

    for (final line in ordered) {
      if (line.text.trim().isEmpty) continue;

      // Compared against the row's last member rather than its first: on a
      // skewed photo a long row drifts downwards, and each fragment is closest
      // to the one printed beside it.
      final row = rows.isEmpty ? null : rows.last;
      final anchor = row?.last;

      if (anchor != null &&
          anchor.verticalOverlapWith(line) >= overlapThreshold) {
        row!.add(line);
      } else {
        rows.add([line]);
      }
    }

    return rows
        .map((row) =>
            ReceiptRow.fromLines(row..sort((a, b) => a.left.compareTo(b.left))))
        .where((row) => row.text.isNotEmpty)
        .toList();
  }

  /// The same grouping flattened to text, for callers with no use for geometry.
  List<String> group(List<ReceiptOcrLine> lines) =>
      groupRows(lines).map((row) => row.text).toList();
}
