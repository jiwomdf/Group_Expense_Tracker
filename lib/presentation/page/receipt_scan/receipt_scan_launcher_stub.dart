import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:flutter/material.dart';

/// Web fallback. Receipt scanning needs ML Kit, which is Android/iOS only, so
/// there is nothing to open here.
///
/// Callers already hide the entry point on web via `PlatformUtil`; this exists
/// so the web build still compiles.
Future<ReceiptScanModel?> openReceiptScanner(BuildContext context) async =>
    null;
