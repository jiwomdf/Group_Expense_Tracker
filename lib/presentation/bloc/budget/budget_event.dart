part of 'budget_bloc.dart';

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object> get props => [];
}

class GetBudgetEvent extends BudgetEvent {
  const GetBudgetEvent();
}

class SetBudgetEvent extends BudgetEvent {
  final int amount;
  const SetBudgetEvent(this.amount);

  @override
  List<Object> get props => [amount];
}

class ClearBudgetEvent extends BudgetEvent {
  const ClearBudgetEvent();
}
