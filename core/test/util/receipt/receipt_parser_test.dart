import 'package:core/util/receipt/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  group('total', () {
    test('reads a total printed with dot thousand separators', () {
      final result = parser.parse('''
INDOMARET
JL SUDIRMAN 12
Indomilk 8.500
Roti Tawar 15.000
TOTAL 23.500
TUNAI 25.000
KEMBALI 1.500
''');

      expect(result.price, 23500);
    });

    test('prefers the real total over the subtotal above it', () {
      final result = parser.parse('''
ALFAMART
SUB TOTAL 50.000
TOTAL 55.000
''');

      expect(result.price, 55000);
    });

    test('prefers grand total over a plain total line', () {
      final result = parser.parse('''
RESTO SEDERHANA
TOTAL 100.000
GRAND TOTAL 111.000
''');

      expect(result.price, 111000);
    });

    test('ignores cash tendered and change when a total exists', () {
      final result = parser.parse('''
WARUNG BU ANI
TOTAL 37.000
TUNAI 50.000
KEMBALIAN 13.000
''');

      expect(result.price, 37000);
    });

    test('falls back to cash paid when no total line is printed', () {
      final result = parser.parse('''
KOPI KENANGAN
Kopi Susu 18.000
TUNAI 18.000
''');

      expect(result.price, 18000);
    });

    test('reads an amount pushed onto the line below its label', () {
      final result = parser.parse('''
TOKO BANGUNAN JAYA
TOTAL
250.000
''');

      expect(result.price, 250000);
    });

    test('drops cents written with a comma', () {
      final result = parser.parse('''
CAFE MOKA
TOTAL 45.000,00
''');

      expect(result.price, 45000);
    });

    test('drops cents written with a dot', () {
      final result = parser.parse('''
CAFE MOKA
TOTAL 45,000.00
''');

      expect(result.price, 45000);
    });

    test('strips a Rp prefix', () {
      final result = parser.parse('''
TOKO SERBA ADA
TOTAL Rp 99.000
''');

      expect(result.price, 99000);
    });

    test('skips the item count on a total item line', () {
      final result = parser.parse('''
SUPERINDO
TOTAL ITEM 3
TOTAL 62.500
''');

      expect(result.price, 62500);
    });

    test('falls back to the largest amount when no keyword is found', () {
      final result = parser.parse('''
TOKO KECIL
Gula 12.000
Beras 65.000
''');

      expect(result.price, 65000);
    });

    test('returns null when the receipt has no plausible amount', () {
      final result = parser.parse('''
TOKO KOSONG
terima kasih
''');

      expect(result.price, isNull);
    });
  });

  group('line items', () {
    test('reads each purchased line as its own item', () {
      final result = parser.parse('''
INDOMARET
Indomilk 8.500
Roti Tawar 15.000
TOTAL 23.500
TUNAI 25.000
KEMBALI 1.500
''');

      expect(result.items.map((i) => i.note), ['Indomilk', 'Roti Tawar']);
      expect(result.items.map((i) => i.price), [8500, 15000]);
    });

    test('items adding up to the total are flagged as matching', () {
      final result = parser.parse('''
INDOMARET
Indomilk 8.500
Roti Tawar 15.000
TOTAL 23.500
''');

      expect(result.itemsTotal, 23500);
      expect(result.itemsMatchTotal, isTrue);
    });

    test('takes the line total, not the unit price, and strips the quantity',
        () {
      final result = parser.parse('''
KOPI KENANGAN
2 Kopi Susu 18.000 36.000
''');

      expect(result.items.single.note, 'Kopi Susu');
      expect(result.items.single.price, 36000);
    });

    test('strips an x-style quantity', () {
      final result = parser.parse('''
WARUNG KOPI
3x Teh Manis 5.000 15.000
''');

      expect(result.items.single.note, 'Teh Manis');
      expect(result.items.single.price, 15000);
    });

    test('drops a line the expense form would reject as too cheap', () {
      // The form requires more than Rp 100, so a cheaper line is left out rather
      // than seeding a row that cannot be saved.
      final result = parser.parse('''
TOKO MURAH
Permen 50
Gula Pasir 12.000
''');

      expect(result.items.map((i) => i.note), ['Gula Pasir']);
    });

    test('excludes the summary block from the items', () {
      final result = parser.parse('''
ALFAMART
Sabun Mandi 12.000
SUB TOTAL 12.000
PPN 1.200
TOTAL 13.200
TUNAI 15.000
KEMBALIAN 1.800
''');

      expect(result.items.map((i) => i.note), ['Sabun Mandi']);
    });

    test('excludes column headers and receipt metadata', () {
      final result = parser.parse('''
EAST REPAIR
TANGGAL 11/02/2019
QTY DESCRIPTION UNIT PRICE AMOUNT
1 Front and rear brake cables 100.00 100.00
''');

      expect(result.items.map((i) => i.note), ['Front and rear brake cables']);
    });

    test('is empty when amounts are stranded on their own lines', () {
      final result = parser.parse('''
TOKO KOLOM
Indomilk
Roti Tawar
8.500
15.000
''');

      expect(result.items, isEmpty);
    });

    test('skips lines whose description is not word-like', () {
      final result = parser.parse('''
TOKO KODE
1234567 9.000
Gula Pasir 12.000
''');

      expect(result.items.map((i) => i.note), ['Gula Pasir']);
    });
  });

  group('printed invoice layout', () {
    // A4 invoices put the total at the top with the label on the far left and
    // the figure on the far right, so ML Kit may emit each column as its own
    // block and separate the two.
    test('reads a receipt total when the label and figure are adjacent', () {
      final result = parser.parse('''
East Repair Inc.
1912 Harvest Lane
New York, NY 12210
Receipt Total
\$154.06
QTY DESCRIPTION UNIT PRICE AMOUNT
1 Front and rear brake cables 100.00 100.00
Subtotal 145.00
Sales Tax 6.25% 9.06
''');

      expect(result.price, 154);
    });

    test('reads a receipt total when the columns are split apart', () {
      final result = parser.parse('''
East Repair Inc.
1912 Harvest Lane
New York, NY 12210
Receipt Total
QTY DESCRIPTION
Front and rear brake cables
RECEIPT DATE
11/02/2019
UNIT PRICE
AMOUNT
100.00
\$154.06
100.00
Subtotal
145.00
''');

      expect(result.price, 154);
    });

    test('does not mistake an AMOUNT column header for the total', () {
      final result = parser.parse('''
East Repair Inc.
AMOUNT
100.00
Receipt Total
\$154.06
''');

      expect(result.price, 154);
    });

    test('does not mistake a postcode for the total', () {
      final result = parser.parse('''
East Repair Inc.
New York, NY 12210
Front and rear brake cables 100.00
''');

      expect(result.price, 100);
    });
  });

  group('merchant', () {
    test('takes the first text line as the merchant', () {
      final result = parser.parse('''
INDOMARET SUDIRMAN
JL. SUDIRMAN NO. 12
TOTAL 23.500
''');

      expect(result.note, 'INDOMARET SUDIRMAN');
    });

    test('skips a leading receipt label and address block', () {
      final result = parser.parse('''
STRUK PEMBELIAN
JL. MERDEKA 8
TELP 021-555
WARUNG PADANG SEJATI
TOTAL 40.000
''');

      expect(result.note, 'WARUNG PADANG SEJATI');
    });

    test('skips numeric noise at the top', () {
      final result = parser.parse('''
1234567890
=========
SUPERINDO
TOTAL 88.000
''');

      expect(result.note, 'SUPERINDO');
    });

    test('is empty when nothing name-like is present', () {
      final result = parser.parse('''
1234567890
9.000
''');

      expect(result.note, isEmpty);
    });
  });

  group('date', () {
    test('parses dd/mm/yyyy', () {
      final result = parser.parse('''
INDOMARET
TANGGAL 17/03/2024
TOTAL 23.500
''');

      expect(result.date, DateTime(2024, 3, 17));
    });

    test('parses dd-mm-yy', () {
      final result = parser.parse('''
ALFAMART
05-02-24 14:30
TOTAL 30.000
''');

      expect(result.date, DateTime(2024, 2, 5));
    });

    test('parses yyyy-mm-dd', () {
      final result = parser.parse('''
TOKO ONLINE
2023-11-09
TOTAL 75.000
''');

      expect(result.date, DateTime(2023, 11, 9));
    });

    test('parses an Indonesian month name', () {
      final result = parser.parse('''
WARUNG SATE
12 Des 2023
TOTAL 55.000
''');

      expect(result.date, DateTime(2023, 12, 12));
    });

    test('rejects an impossible day for the month', () {
      final result = parser.parse('''
TOKO ANEH
31/02/2024
TOTAL 10.000
''');

      expect(result.date, isNull);
    });

    test('rejects a future date', () {
      final nextYear = DateTime.now().year + 1;
      final result = parser.parse('''
TOKO MASA DEPAN
01/01/$nextYear
TOTAL 10.000
''');

      expect(result.date, isNull);
    });

    test('is null when no date is printed', () {
      final result = parser.parse('''
TOKO TANPA TANGGAL
TOTAL 20.000
''');

      expect(result.date, isNull);
    });
  });

  group('isEmpty', () {
    test('is true when neither merchant nor total was found', () {
      expect(parser.parse('....\n----').isEmpty, isTrue);
    });

    test('is false when a total was found', () {
      expect(parser.parse('TOKO\nTOTAL 15.000').isEmpty, isFalse);
    });
  });
}
