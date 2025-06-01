import 'package:bloc/bloc.dart';
import 'package:core/data/network/request/insert_expense_request.dart';
import 'package:core/data/network/request/update_expense_request.dart';
import 'package:core/domain/model/expense_category_model.dart';
import 'package:core/repository/firestore_repository.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final FirestoreRepository _firestoreRepository;

  List<ExpenseCategoryModel> _tempExpense = [];

  ExpenseBloc(this._firestoreRepository) : super(ExpenseLoading()) {
    on<InsertExpenseEvent>((event, emit) async {
      var expenses = await _firestoreRepository
          .insertExpense(event.expenseRequest.toJson());
      switch (expenses.status) {
        case Status.success:
          emit(const ExpenseDataChanged(true));
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<InsertBatchExpenseEvent>((event, emit) async {
      var expenses = await _firestoreRepository.insertBatchExpense(
          listExpenseRequest: event.listExpenseRequest);

      switch (expenses.status) {
        case Status.success:
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<UpdateBatchExpenseEvent>((event, emit) async {
      var expenses = await _firestoreRepository.updateBatchExpense(
        listdata: event.updateBatchExpense,
      );

      switch (expenses.status) {
        case Status.success:
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<UpdateExpenseEvent>((event, emit) async {
      var expenses = await _firestoreRepository.updateExpense(
        id: event.expenseRequest.id,
        expenseRequest: event.expenseRequest.toJson(),
      );

      switch (expenses.status) {
        case Status.success:
          emit(const ExpenseDataChanged(true));
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<DeleteExpenseEvent>((event, emit) async {
      var expenses = await _firestoreRepository.deleteExpense(event.id);
      switch (expenses.status) {
        case Status.success:
          emit(const ExpenseDataChanged(true));
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<GetExpenseEvent>((event, emit) async {
      emit(ExpenseLoading());
      var expenses = await _firestoreRepository.getExpense(
          event.month, event.year, event.subCategoryId);
      switch (expenses.status) {
        case Status.success:
          _tempExpense = expenses.data ?? [];
          emit(ExpenseHasData(expenses.data ?? []));
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<GetAllExpenseEvent>((event, emit) async {
      emit(ExpenseLoading());
      var expenses = await _firestoreRepository.getAllExpense();
      switch (expenses.status) {
        case Status.success:
          _tempExpense = expenses.data ?? [];
          emit(ExpenseHasData(expenses.data ?? []));
          break;
        case Status.error:
          emit(ExpenseError(expenses.failure?.message ?? ""));
          break;
      }
    });

    on<FilterExpenseEvent>((event, emit) async {
      try {
        emit(ExpenseLoading());
        var paramDate = event.date.toDateGlobalFormat()!;
        var filteredExpense = _tempExpense.where((i) {
          var iDate = i.date.toDateGlobalFormat()!;
          var isExactMonth = paramDate.month == iDate.month;
          var isExactYear = paramDate.year == iDate.year;
          return isExactMonth && isExactYear;
        }).toList();
        emit(ExpenseHasData(filteredExpense));
      } catch (ex) {
        emit(ExpenseError(ex.toString()));
      }
    });

    on<ResetExpenseEvent>((event, emit) async {
      emit(ExpenseInitiated());
    });
  }
}
