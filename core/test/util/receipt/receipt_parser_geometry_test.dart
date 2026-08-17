import 'package:core/domain/model/receipt_ocr_line.dart';
import 'package:core/util/receipt/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

ReceiptOcrLine at(
  String text, {
  required double top,
  required double left,
  double width = 160,
  double height = 20,
}) =>
    ReceiptOcrLine(
      text: text,
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
    );

void main() {
  const parser = ReceiptParser();

  test('pairs a total with the amount printed opposite it', () {
    // The invoicehome layout: label far left, figure far right, and ML Kit
    // reports them in unrelated blocks. Flattened to text this used to read the
    // AMOUNT column header and return the first line item instead.
    final result = parser.parseLines([
      at('East Repair Inc.', top: 0, left: 40),
      at('Receipt Total', top: 300, left: 40),
      at('\$154.06', top: 300, left: 560),
      at('QTY DESCRIPTION UNIT PRICE AMOUNT', top: 380, left: 40, width: 620),
      at('1 Front and rear brake cables', top: 420, left: 40),
      at('100.00', top: 420, left: 560),
      at('Subtotal', top: 500, left: 400),
      at('145.00', top: 500, left: 560),
    ]);

    expect(result.price, 154);
  });

  test('recovers items whose amount sits in a separate column', () {
    // Flattened text cannot pair these, so `parse` yields no items at all.
    final lines = [
      at('INDOMARET', top: 0, left: 40),
      at('Indomilk', top: 100, left: 40),
      at('8.500', top: 100, left: 400),
      at('Roti Tawar', top: 140, left: 40),
      at('15.000', top: 140, left: 400),
      at('TOTAL', top: 200, left: 40),
      at('23.500', top: 200, left: 400),
    ];

    final withGeometry = parser.parseLines(lines);
    final flattened = parser.parse(lines.map((l) => l.text).join('\n'));

    expect(withGeometry.items.map((i) => i.note), ['Indomilk', 'Roti Tawar']);
    expect(withGeometry.items.map((i) => i.price), [8500, 15000]);
    expect(withGeometry.price, 23500);
    expect(withGeometry.itemsMatchTotal, isTrue);

    // The point of the geometry path: the same OCR output is unusable without it.
    expect(flattened.items, isEmpty);
  });

  test('keeps the merchant from the top of the page', () {
    final result = parser.parseLines([
      at('WARUNG PADANG SEJATI', top: 0, left: 40),
      at('JL. MERDEKA 8', top: 40, left: 40),
      at('TOTAL', top: 200, left: 40),
      at('40.000', top: 200, left: 400),
    ]);

    expect(result.note, 'WARUNG PADANG SEJATI');
    expect(result.price, 40000);
  });

  test('reads a date split across the page', () {
    final result = parser.parseLines([
      at('INDOMARET', top: 0, left: 40),
      at('TANGGAL', top: 60, left: 40),
      at('17/03/2024', top: 60, left: 400),
      at('TOTAL', top: 200, left: 40),
      at('23.500', top: 200, left: 400),
    ]);

    expect(result.date, DateTime(2024, 3, 17));
  });

  test('keeps the raw text for the review screen', () {
    final result = parser.parseLines([
      at('INDOMARET', top: 0, left: 40),
      at('TOTAL', top: 200, left: 40),
      at('23.500', top: 200, left: 400),
    ]);

    expect(result.rawText, contains('INDOMARET'));
    expect(result.rawText, contains('23.500'));
  });
}
