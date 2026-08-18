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

  group('item names', () {
    test('keeps a size printed inside the name', () {
      final result = parser.parse('''
INDOMARET
AQUA 600ML 3.500
TOTAL 3.500
''');

      expect(result.items.map((i) => i.note), ['AQUA 600ML']);
      expect(result.items.map((i) => i.price), [3500]);
    });

    test('drops the quantity and unit price trailing the name', () {
      final result = parser.parse('''
INDOMARET
INDOMIE GORENG 2 3.500 7.000
TOTAL 7.000
''');

      expect(result.items.map((i) => i.note), ['INDOMIE GORENG']);
      expect(result.items.map((i) => i.price), [7000]);
    });

    test('takes the name from the row above a quantity line', () {
      final result = parser.parse('''
WARUNG KOPI
KOPI SUSU
2 x 15.000 30.000
TOTAL 30.000
''');

      expect(result.items.map((i) => i.note), ['KOPI SUSU']);
      expect(result.items.map((i) => i.price), [30000]);
    });

    test('multiplies a quantity by the unit price with no line total printed',
        () {
      final result = parser.parse('''
WARUNG SATE
BAKSO URAT 2 x 20.000
TOTAL 40.000
''');

      expect(result.items.map((i) => i.note), ['BAKSO URAT']);
      expect(result.items.map((i) => i.price), [40000]);
    });
  });

  group('amounts', () {
    test('reads a two-digit group as grouping on a whole-rupiah receipt', () {
      final result = parser.parse('''
TOKO ROTI
ROTI TAWAR 15.00
KUE SUS 12.000
TOTAL 27.000
''');

      expect(result.items.map((i) => i.price), [1500, 12000]);
    });

    test('reads letters the engine mistook for digits inside an amount', () {
      final result = parser.parse('''
INDOMARET
GULA PASIR 1S.OOO
TOTAL 15.000
''');

      expect(result.items.map((i) => i.note), ['GULA PASIR']);
      expect(result.items.map((i) => i.price), [15000]);
    });

    test('ignores a bare run too long to be a price', () {
      final result = parser.parse('''
INDOMARET
MEMBER CARD 6281234567890
GULA PASIR 15.000
TOTAL 15.000
''');

      expect(result.items.map((i) => i.note), ['GULA PASIR']);
    });
  });

  group('reconciling against the total', () {
    test('drops a line that is double counted', () {
      final result = parser.parse('''
INDOMARET
INDOMILK 8.500
ROTI TAWAR 15.000
BONUS 8.500
TOTAL 23.500
''');

      expect(result.items.map((i) => i.note), ['ROTI TAWAR', 'BONUS']);
      expect(result.itemsMatchTotal, isTrue);
    });

    test('keeps every line when nothing reconciles it', () {
      final result = parser.parse('''
INDOMARET
INDOMILK 8.500
ROTI TAWAR 15.000
TOTAL 20.000
''');

      expect(result.items.length, 2);
      expect(result.itemsMatchTotal, isFalse);
    });

    test('ignores a line priced above the total', () {
      final result = parser.parse('''
INDOMARET
INDOMILK 8.500
KARTU 99.000
TOTAL 8.500
''');

      expect(result.items.map((i) => i.note), ['INDOMILK']);
    });
  });

  group('price column', () {
    test('takes the amount in the price column, not one inside the name', () {
      final result = parser.parseLines([
        at('INDOMARET', top: 0, left: 40),
        at('AQUA 600ML', top: 100, left: 40),
        at('3.500', top: 100, left: 400, width: 80),
        at('SUSU 1 LITER', top: 140, left: 40),
        at('18.900', top: 140, left: 400, width: 80),
        at('TOTAL', top: 200, left: 40),
        at('22.400', top: 200, left: 400, width: 80),
      ]);

      expect(result.items.map((i) => i.note), ['AQUA 600ML', 'SUSU 1 LITER']);
      expect(result.items.map((i) => i.price), [3500, 18900]);
      expect(result.itemsMatchTotal, isTrue);
    });

    test('ignores lines the engine was unsure of', () {
      final result = parser.parseLines([
        at('INDOMARET', top: 0, left: 40),
        const ReceiptOcrLine(
          text: 'XX//XX 99.000',
          left: 40,
          top: 100,
          right: 500,
          bottom: 120,
          confidence: 0.1,
        ),
        at('GULA PASIR', top: 140, left: 40),
        at('15.000', top: 140, left: 400, width: 80),
      ]);

      expect(result.items.map((i) => i.note), ['GULA PASIR']);
      expect(result.price, 15000);
    });
  });
}
