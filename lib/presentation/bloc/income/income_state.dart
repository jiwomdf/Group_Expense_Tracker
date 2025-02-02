part of 'income_cubit.dart';

sealed class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object> get props => [];
}

final class IncomeInitial extends IncomeState {}

final class IncomeUpdated extends IncomeState {
  final bool isSuccess;

  const IncomeUpdated({required this.isSuccess});
}

final class IncomeHasData extends IncomeState {
  final int income;

  const IncomeHasData({required this.income});
}
