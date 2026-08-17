part of 'receipt_scan_bloc.dart';

sealed class ReceiptScanState extends Equatable {
  const ReceiptScanState();

  @override
  List<Object> get props => [];
}

final class ReceiptScanInitial extends ReceiptScanState {
  const ReceiptScanInitial();
}

final class ReceiptScanLoading extends ReceiptScanState {
  const ReceiptScanLoading();
}

class ReceiptScanError extends ReceiptScanState {
  final String message;

  const ReceiptScanError(this.message);

  @override
  List<Object> get props => [message];
}

class ReceiptScanHasData extends ReceiptScanState {
  final ReceiptScanModel result;
  final String imagePath;

  const ReceiptScanHasData(this.result, this.imagePath);

  @override
  List<Object> get props => [imagePath, result.rawText];
}
