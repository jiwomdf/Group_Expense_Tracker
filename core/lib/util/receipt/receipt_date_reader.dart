import 'package:core/util/receipt/receipt_keywords.dart';

/// Finds the transaction date printed on a receipt.
class ReceiptDateReader {
  const ReceiptDateReader();

  static final _numeric = RegExp(r'(\d{1,4})[/\-.](\d{1,2})[/\-.](\d{2,4})');

  static final _textual = RegExp(
      r'(\d{1,2})[\s\-/]*([a-z]{3,9})[\s\-/]*(\d{2,4})',
      caseSensitive: false);

  /// Returns the first plausible date, or null when the receipt printed none.
  DateTime? read(List<String> rows) {
    for (final row in rows) {
      final numeric = _numeric.firstMatch(row);
      if (numeric != null) {
        final date = _fromNumeric(numeric);
        if (date != null) return date;
      }

      final textual = _textual.firstMatch(row);
      if (textual != null) {
        final date = _fromTextual(textual);
        if (date != null) return date;
      }
    }

    return null;
  }

  /// Handles both `dd/mm/yyyy` (the Indonesian norm) and `yyyy-mm-dd`.
  DateTime? _fromNumeric(RegExpMatch match) {
    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    final third = int.parse(match.group(3)!);

    if (match.group(1)!.length == 4) {
      return _build(third, second, first);
    }
    return _build(first, second, third);
  }

  DateTime? _fromTextual(RegExpMatch match) {
    final name = match.group(2)!.toLowerCase().substring(0, 3);
    final month = ReceiptKeywords.monthNames[name];
    if (month == null) return null;

    return _build(
      int.parse(match.group(1)!),
      month,
      int.parse(match.group(3)!),
    );
  }

  /// Rejects impossible or implausible dates so a stray serial number cannot
  /// masquerade as the transaction date.
  DateTime? _build(int day, int month, int year) {
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    if (year < 100) year += 2000;
    if (year < 2000) return null;

    final date = DateTime(year, month, day);

    // Guard against overflow, e.g. 31/02 silently becoming 02/03.
    if (date.day != day || date.month != month) return null;
    // A receipt cannot be from the future, allowing a day for timezone skew.
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;

    return date;
  }
}
