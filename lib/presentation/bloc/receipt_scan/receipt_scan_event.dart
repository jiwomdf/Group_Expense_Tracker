part of 'receipt_scan_bloc.dart';

sealed class ReceiptScanEvent extends Equatable {
  const ReceiptScanEvent();

  @override
  List<Object> get props => [];
}

class ScanReceiptEvent extends ReceiptScanEvent {
  final String imagePath;

  const ScanReceiptEvent(this.imagePath);

  @override
  List<Object> get props => [imagePath];
}

class ResetReceiptScanEvent extends ReceiptScanEvent {
  const ResetReceiptScanEvent();
}
