part of 'expense_bloc.dart';

sealed class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object> get props => [];
}

class UpdateExpenseEvent extends ExpenseEvent {
  final UpdateExpenseRequest expenseRequest;

  const UpdateExpenseEvent(this.expenseRequest);

  @override
  List<Object> get props => [];
}

class UpdateBatchExpenseEvent extends ExpenseEvent {
  final List<Map<String, dynamic>> updateBatchExpense;

  const UpdateBatchExpenseEvent(this.updateBatchExpense);

  @override
  List<Object> get props => [];
}

class InsertExpenseEvent extends ExpenseEvent {
  final InsertExpenseRequest expenseRequest;

  const InsertExpenseEvent(this.expenseRequest);

  @override
  List<Object> get props => [];
}

class InsertBatchExpenseEvent extends ExpenseEvent {
  final List<InsertExpenseRequest> listExpenseRequest;

  const InsertBatchExpenseEvent(this.listExpenseRequest);

  @override
  List<Object> get props => [];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String id;

  const DeleteExpenseEvent(this.id);

  @override
  List<Object> get props => [];
}

class GetExpenseEvent extends ExpenseEvent {
  final int month;
  final int year;
  final String subCategoryId;
  const GetExpenseEvent(this.month, this.year, this.subCategoryId);

  @override
  List<Object> get props => [month, year];
}

class GetAllExpenseEvent extends ExpenseEvent {
  const GetAllExpenseEvent();

  @override
  List<Object> get props => [];
}

class FilterExpenseEvent extends ExpenseEvent {
  final String date;
  const FilterExpenseEvent(this.date);

  @override
  List<Object> get props => [date];
}

class ResetExpenseEvent extends ExpenseEvent {
  const ResetExpenseEvent();

  @override
  List<Object> get props => [];
}
