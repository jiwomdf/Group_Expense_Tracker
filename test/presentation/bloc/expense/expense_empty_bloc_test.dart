import 'package:bloc_test/bloc_test.dart';
import 'package:core/domain/model/expense_category_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:mockito/mockito.dart';

import '../../../helper/test_helper.mocks.dart';

void main() {
  late ExpenseBloc expenseBloc;
  late MockFirestoreRepository mockFirestoreRepository;
  late ExpenseCategoryModel expense;

  setUp(() {
    mockFirestoreRepository = MockFirestoreRepository();
    expenseBloc = ExpenseBloc(mockFirestoreRepository);

    expense = ExpenseCategoryModel(
      id: "1",
      email: "katili@example.com",
      note: "Indomaret",
      price: 23500,
      date: "17/03/2024",
      categoryId: "c1",
      categoryName: "primary needs",
      categoryColor: 0xFFFFFFFF,
      subCategoryId: "s1",
      subCategoryName: "groceries",
      subCategoryColor: 0xFFFFFFFF,
      year: "2024",
      month: "03",
      dayOfMonth: "17",
      timeStamp: "00:20:46 17/03/2024",
      status: "A",
    );
  });

  blocTest<ExpenseBloc, ExpenseState>(
    'Should emit [Loading, ExpenseEmpty] when the month has no expenses',
    build: () {
      when(mockFirestoreRepository.getExpense(3, 2024, ""))
          .thenAnswer((_) async => ResourceUtil.success([]));
      return expenseBloc;
    },
    act: (bloc) => bloc.add(const GetExpenseEvent(3, 2024, "")),
    expect: () => [
      ExpenseLoading(),
      const ExpenseEmpty(),
    ],
  );

  blocTest<ExpenseBloc, ExpenseState>(
    'Should emit [Loading, ExpenseHasData] when the month has expenses',
    build: () {
      when(mockFirestoreRepository.getExpense(3, 2024, ""))
          .thenAnswer((_) async => ResourceUtil.success([expense]));
      return expenseBloc;
    },
    act: (bloc) => bloc.add(const GetExpenseEvent(3, 2024, "")),
    expect: () => [
      ExpenseLoading(),
      ExpenseHasData([expense]),
    ],
  );

  blocTest<ExpenseBloc, ExpenseState>(
    'Should emit [Loading, ExpenseEmpty] when getAll returns nothing',
    build: () {
      when(mockFirestoreRepository.getAllExpense())
          .thenAnswer((_) async => ResourceUtil.success([]));
      return expenseBloc;
    },
    act: (bloc) => bloc.add(const GetAllExpenseEvent()),
    expect: () => [
      ExpenseLoading(),
      const ExpenseEmpty(),
    ],
  );
}
