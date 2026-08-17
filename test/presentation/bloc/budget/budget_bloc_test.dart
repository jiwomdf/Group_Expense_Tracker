import 'package:bloc_test/bloc_test.dart';
import 'package:core/data/pref/budget_pref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/budget/budget_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real `BudgetPref` runs against the in-memory SharedPreferences, so the
/// tests cover the storage round trip as well as the bloc.
Future<BudgetPref> buildPref(Map<String, Object> initialValues) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return BudgetPref(prefs: await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  blocTest<BudgetBloc, BudgetState>(
    'Should emit [Loading, NotSet] when no budget was ever saved',
    build: () => BudgetBloc(_pref),
    setUp: () async => _pref = await buildPref({}),
    act: (bloc) => bloc.add(const GetBudgetEvent()),
    expect: () => [isA<BudgetLoading>(), const BudgetNotSet()],
  );

  blocTest<BudgetBloc, BudgetState>(
    'Should emit [Loading, HasData] with the stored amount',
    build: () => BudgetBloc(_pref),
    setUp: () async =>
        _pref = await buildPref({BudgetPref.monthlyBudgetPref: 2500000}),
    act: (bloc) => bloc.add(const GetBudgetEvent()),
    expect: () => [isA<BudgetLoading>(), const BudgetHasData(2500000)],
  );

  blocTest<BudgetBloc, BudgetState>(
    'Should persist the amount and flag the change when the budget is set',
    build: () => BudgetBloc(_pref),
    setUp: () async => _pref = await buildPref({}),
    act: (bloc) => bloc.add(const SetBudgetEvent(1000000)),
    expect: () => [const BudgetHasData(1000000, isJustChanged: true)],
    verify: (_) async {
      final stored = await _pref.getMonthlyBudget();
      expect(stored.data, 1000000);
    },
  );

  blocTest<BudgetBloc, BudgetState>(
    'Should treat a budget of zero as not set',
    build: () => BudgetBloc(_pref),
    setUp: () async => _pref = await buildPref({}),
    act: (bloc) => bloc.add(const SetBudgetEvent(0)),
    expect: () => [const BudgetNotSet(isJustChanged: true)],
  );

  blocTest<BudgetBloc, BudgetState>(
    'Should drop the stored amount when the budget is cleared',
    build: () => BudgetBloc(_pref),
    setUp: () async =>
        _pref = await buildPref({BudgetPref.monthlyBudgetPref: 750000}),
    act: (bloc) => bloc.add(const ClearBudgetEvent()),
    expect: () => [const BudgetNotSet(isJustChanged: true)],
    verify: (_) async {
      final stored = await _pref.getMonthlyBudget();
      expect(stored.data, 0);
    },
  );
}

late BudgetPref _pref;
