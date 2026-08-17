import 'package:bloc/bloc.dart';
import 'package:core/data/pref/budget_pref.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetPref _budgetPref;

  BudgetBloc(this._budgetPref) : super(BudgetLoading()) {
    on<GetBudgetEvent>((event, emit) async {
      emit(BudgetLoading());
      var budget = await _budgetPref.getMonthlyBudget();

      switch (budget.status) {
        case Status.success:
          emit(_dataOrNotSet(budget.data ?? 0));
          break;
        case Status.error:
          emit(BudgetError(budget.failure?.message ?? ""));
          break;
      }
    });

    on<SetBudgetEvent>((event, emit) async {
      var result = await _budgetPref.setMonthlyBudget(event.amount);

      switch (result.status) {
        case Status.success:
          emit(_dataOrNotSet(event.amount, isJustChanged: true));
          break;
        case Status.error:
          emit(BudgetError(result.failure?.message ?? ""));
          break;
      }
    });

    on<ClearBudgetEvent>((event, emit) async {
      var result = await _budgetPref.clearMonthlyBudget();

      switch (result.status) {
        case Status.success:
          emit(const BudgetNotSet(isJustChanged: true));
          break;
        case Status.error:
          emit(BudgetError(result.failure?.message ?? ""));
          break;
      }
    });
  }

  /// A budget of zero is the same as no budget: the dashboard should say
  /// "not set" instead of reporting every expense as over budget.
  BudgetState _dataOrNotSet(int amount, {bool isJustChanged = false}) =>
      amount <= 0
          ? BudgetNotSet(isJustChanged: isJustChanged)
          : BudgetHasData(amount, isJustChanged: isJustChanged);
}
