import 'package:core/util/resource/resource_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/widget/filter_widget.dart';
import 'package:mockito/mockito.dart';

import '../../helper/test_helper.mocks.dart';

void main() {
  late MockFirestoreRepository repository;
  late List<List<dynamic>> calls;

  setUp(() {
    repository = MockFirestoreRepository();
    when(repository.getSubCategoryWithCache())
        .thenAnswer((_) async => ResourceUtil.success([]));
    calls = [];
  });

  /// Mirrors the dashboard: the parent owns the selection and feeds it back in,
  /// which is what keeps the dropdown and the loaded data in step.
  Future<void> pumpFilter(WidgetTester tester,
      {required int ddlMonth, required int ddlYear}) async {
    var month = ddlMonth;
    var year = ddlYear;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<SubcategoryBloc>(
          create: (_) => SubcategoryBloc(repository),
          child: StatefulBuilder(
            builder: (context, setState) => FilterWidget(
              ddlMonth: month,
              ddlYear: year,
              onDdlChanged: (m, y, subCategory, subCategoryId) {
                calls.add([m, y, subCategory, subCategoryId]);
                setState(() {
                  month = m;
                  year = y;
                });
              },
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> pickMonth(WidgetTester tester, String month) async {
    await tester.tap(find.byType(DropdownButton<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(month).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Should report the picked month to the dashboard',
      (tester) async {
    await pumpFilter(tester, ddlMonth: 8, ddlYear: 2026);

    await pickMonth(tester, 'March');

    expect(calls.single[0], 3);
    expect(calls.single[1], 2026);
  });

  testWidgets('Should keep showing the picked month, not the current one',
      (tester) async {
    await pumpFilter(tester, ddlMonth: 8, ddlYear: 2026);

    await pickMonth(tester, 'March');

    expect(find.text('March'), findsOneWidget);
    expect(find.text('August'), findsNothing);
  });

  testWidgets('Should show the month it was opened with', (tester) async {
    await pumpFilter(tester, ddlMonth: 3, ddlYear: 2026);

    expect(find.text('March'), findsOneWidget);
  });

  testWidgets('Should keep the selection when the dashboard rebuilds it',
      (tester) async {
    await pumpFilter(tester, ddlMonth: 3, ddlYear: 2026);

    // The dashboard swaps the widgets above the filter as expenses load, which
    // used to discard the filter's own state.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BlocProvider<SubcategoryBloc>(
          create: (_) => SubcategoryBloc(repository),
          child: FilterWidget(
              ddlMonth: 3,
              ddlYear: 2026,
              onDdlChanged: (m, y, subCategory, subCategoryId) {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('March'), findsOneWidget);
  });
}
