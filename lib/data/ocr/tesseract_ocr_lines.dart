import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:core/domain/model/receipt_ocr_line.dart';

/// Reads Tesseract.js's result object into the parser's plugin-free model.
class TesseractOcrLines {
  const TesseractOcrLines._();

  /// The `data` object holding `text` and `lines`.
  static JSObject? dataOf(JSObject result) =>
      result.getProperty('data'.toJS) as JSObject?;

  static String textOf(JSObject data) =>
      (data.getProperty('text'.toJS) as JSString?)?.toDart ?? '';

  /// Maps `data.lines`, each carrying a `bbox` and a confidence percentage.
  ///
  /// Returns empty when the build reports no line boxes, which leaves the
  /// caller to fall back to the text-only parse.
  static List<ReceiptOcrLine> from(JSObject data) {
    final raw = data.getProperty('lines'.toJS);
    if (raw == null || !raw.isA<JSArray>()) return const [];

    final lines = <ReceiptOcrLine>[];

    for (final entry in (raw as JSArray).toDart) {
      final line = entry as JSObject?;
      if (line == null) continue;

      final text = (line.getProperty('text'.toJS) as JSString?)?.toDart ?? '';
      if (text.trim().isEmpty) continue;

      final box = line.getProperty('bbox'.toJS) as JSObject?;
      if (box == null) continue;

      lines.add(ReceiptOcrLine(
        text: text.trim(),
        left: _number(box, 'x0'),
        top: _number(box, 'y0'),
        right: _number(box, 'x1'),
        bottom: _number(box, 'y1'),
        // Tesseract reports 0-100 where ML Kit reports 0-1, so it is scaled to
        // match and the log can print one format for both engines.
        confidence: _confidence(line),
      ));
    }

    return lines;
  }

  static double? _confidence(JSObject line) {
    final value =
        (line.getProperty('confidence'.toJS) as JSNumber?)?.toDartDouble;
    return value == null ? null : value / 100;
  }

  static double _number(JSObject object, String key) =>
      (object.getProperty(key.toJS) as JSNumber?)?.toDartDouble ?? 0;
}
