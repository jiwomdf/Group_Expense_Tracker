import 'package:core/util/receipt/receipt_parser.dart';
import 'package:core/util/receipt/receipt_scan_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  test('records every stage from rows to total', () {
    final log = ReceiptScanLog();

    final result = parser.parse('''
INDOMARET
Indomilk 8.500
Roti Tawar 15.000
TOTAL 23.500
''', log: log);

    final trace = result.log.join('\n');

    expect(trace, contains('Rows:'));
    expect(trace, contains('Merchant: "INDOMARET"'));
    expect(trace, contains('Total: Rp 23500'));
    expect(trace, contains('Items: 2 found'));
    expect(trace, contains('matches the total exactly'));
  });

  test('names the keyword and row the total came from', () {
    final log = ReceiptScanLog();

    parser.parse('''
ALFAMART
SUB TOTAL 50.000
GRAND TOTAL 55.000
''', log: log);

    final trace = log.entries.join('\n');

    expect(trace, contains('matched "grand total"'));
    expect(trace, contains('tier 1'));
  });

  test('says when it fell back to the largest amount', () {
    final log = ReceiptScanLog();

    parser.parse('''
TOKO KECIL
Gula 12.000
Beras 65.000
''', log: log);

    expect(log.entries.join('\n'),
        contains('fell back to the largest money-shaped amount'));
  });

  test('reports a mismatch between the items and the total', () {
    final log = ReceiptScanLog();

    parser.parse('''
ALFAMART
Sabun Mandi 12.000
PPN 1.200
TOTAL 13.200
''', log: log);

    expect(log.entries.join('\n'), contains('differs from the total by Rp'));
  });

  test('parsing without a log still works', () {
    final result = parser.parse('TOKO\nTOTAL 15.000');

    expect(result.price, 15000);
    expect(result.log, isEmpty);
  });

  test('entries are timestamped', () {
    final log = ReceiptScanLog();
    log.stage('Image', '120 KB');

    expect(log.entries.single, matches(RegExp(r'^\[\s*\d+ms\] Image: 120 KB$')));
  });
}
