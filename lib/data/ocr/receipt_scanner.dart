/// Picks the OCR engine for the platform being compiled.
///
/// ML Kit on Android and iOS, Tesseract.js in the browser. Both expose the same
/// `ReceiptScanner` API and both feed the platform-neutral parser in `core`, so
/// nothing above this line knows which engine ran.
library;

export 'receipt_scanner_web.dart'
    if (dart.library.io) 'receipt_scanner_io.dart';
