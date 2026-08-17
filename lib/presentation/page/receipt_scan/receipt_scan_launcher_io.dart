import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:flutter/material.dart';
import 'package:group_expense_tracker/presentation/page/receipt_scan/receipt_scan_page.dart';

/// Opens the scanner and returns what the user accepted, or null if they backed
/// out without scanning.
///
/// Pushed directly instead of by route name so the parsed result can come back
/// through `Navigator.pop`.
Future<ReceiptScanModel?> openReceiptScanner(BuildContext context) {
  return Navigator.of(context).push<ReceiptScanModel>(
    MaterialPageRoute(builder: (_) => const ReceiptScanPage()),
  );
}
