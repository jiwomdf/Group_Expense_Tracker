part of 'expense_template_bloc.dart';

sealed class ExpenseTemplateState extends Equatable {
  const ExpenseTemplateState();

  @override
  List<Object> get props => [];
}

final class ExpenseTemplateLoading extends ExpenseTemplateState {}

/// `isJustChanged` marks the state that followed a save or a delete, so the page
/// can confirm with a snackbar without mistaking a plain reload for an edit.
/// Same convention as [BudgetState].
final class ExpenseTemplateEmpty extends ExpenseTemplateState {
  final bool isJustChanged;

  const ExpenseTemplateEmpty({this.isJustChanged = false});

  @override
  List<Object> get props => [isJustChanged];
}

final class ExpenseTemplateHasData extends ExpenseTemplateState {
  final List<ExpenseTemplateModel> result;
  final bool isJustChanged;

  const ExpenseTemplateHasData(this.result, {this.isJustChanged = false});

  @override
  List<Object> get props =>
      [result.map((item) => item.id).join(), isJustChanged];
}

final class ExpenseTemplateError extends ExpenseTemplateState {
  final String message;

  const ExpenseTemplateError(this.message);

  @override
  List<Object> get props => [message];
}
