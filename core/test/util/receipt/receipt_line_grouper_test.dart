import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/util/receipt/receipt_line_grouper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a line at a given band, with x defaulting to a narrow box so tests
/// only have to say what they care about.
ReceiptOcrLine line(
  String text, {
  required double top,
  required double bottom,
  double left = 0,
  double right = 100,
}) =>
    ReceiptOcrLine(
        text: text, left: left, top: top, right: right, bottom: bottom);

void main() {
  const grouper = ReceiptLineGrouper();

  test('joins fragments that share a horizontal band, left to right', () {
    final rows = grouper.group([
      line('23.500', top: 100, bottom: 120, left: 400, right: 500),
      line('TOTAL', top: 102, bottom: 122, left: 0, right: 80),
    ]);

    expect(rows, ['TOTAL 23.500']);
  });

  test('keeps separate bands as separate rows, top to bottom', () {
    final rows = grouper.group([
      line('TOTAL 23.500', top: 100, bottom: 120),
      line('INDOMARET', top: 10, bottom: 30),
      line('Indomilk 8.500', top: 50, bottom: 70),
    ]);

    expect(rows, ['INDOMARET', 'Indomilk 8.500', 'TOTAL 23.500']);
  });

  test('tolerates the baseline drift of a hand-held photo', () {
    // Right-hand fragment sits a few pixels low, as on a slightly rotated shot.
    final rows = grouper.group([
      line('Roti Tawar', top: 100, bottom: 120, left: 0, right: 200),
      line('15.000', top: 106, bottom: 126, left: 400, right: 500),
    ]);

    expect(rows, ['Roti Tawar 15.000']);
  });

  test('does not merge rows that merely touch', () {
    final rows = grouper.group([
      line('Indomilk 8.500', top: 100, bottom: 120),
      line('Roti Tawar 15.000', top: 119, bottom: 139),
    ]);

    expect(rows, ['Indomilk 8.500', 'Roti Tawar 15.000']);
  });

  test('drops blank fragments', () {
    final rows = grouper.group([
      line('  ', top: 100, bottom: 120, left: 0, right: 10),
      line('TOTAL 23.500', top: 100, bottom: 120, left: 20, right: 200),
    ]);

    expect(rows, ['TOTAL 23.500']);
  });

  test('returns nothing for no input', () {
    expect(grouper.group([]), isEmpty);
  });
}
