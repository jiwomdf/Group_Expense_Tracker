/// Mobile-only entry point for receipt scanning.
///
/// ML Kit's Dart code imports `dart:io`, so anything that reaches
/// `ReceiptScanPage` fails to compile for web. Callers import this file and get
/// the real scanner on Android and iOS, or a no-op on web.
library;

export 'receipt_scan_launcher_stub.dart'
    if (dart.library.io) 'receipt_scan_launcher_io.dart';
