import 'package:bloc/bloc.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';
import 'package:group_expense_tracker/data/repository/receipt_scan_repository.dart';

part 'receipt_scan_event.dart';
part 'receipt_scan_state.dart';

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, ReceiptScanState> {
  final ReceiptScanRepository _receiptScanRepository;

  ReceiptScanBloc(this._receiptScanRepository)
      : super(const ReceiptScanInitial()) {
    on<ScanReceiptEvent>((event, emit) async {
      emit(const ReceiptScanLoading());

      final result = await _receiptScanRepository.scan(event.imagePath);

      switch (result.status) {
        case Status.success:
          final scan = result.data;
          if (scan == null || scan.isEmpty) {
            emit(const ReceiptScanError(
                "Could not read a total off this receipt. You can still enter it manually."));
          } else {
            emit(ReceiptScanHasData(scan, event.imagePath));
          }
          break;
        case Status.error:
          emit(ReceiptScanError(result.failure?.message ?? ""));
          break;
      }
    });

    on<ResetReceiptScanEvent>((event, emit) {
      emit(const ReceiptScanInitial());
    });
  }
}
