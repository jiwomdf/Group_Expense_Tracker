part of 'budget_bloc.dart';

sealed class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object> get props => [];
}

final class BudgetLoading extends BudgetState {}

/// `isJustChanged` marks the state that came from the user saving or clearing
/// the budget, so the page can confirm with a snackbar without mistaking a
/// plain reload for an edit.
final class BudgetNotSet extends BudgetState {
  final bool isJustChanged;

  const BudgetNotSet({this.isJustChanged = false});

  @override
  List<Object> get props => [isJustChanged];
}

final class BudgetHasData extends BudgetState {
  final int amount;
  final bool isJustChanged;

  const BudgetHasData(this.amount, {this.isJustChanged = false});

  @override
  List<Object> get props => [amount, isJustChanged];
}

final class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object> get props => [message];
}
