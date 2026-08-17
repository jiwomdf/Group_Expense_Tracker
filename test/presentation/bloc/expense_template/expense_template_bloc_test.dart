import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:core/data/pref/expense_template_pref.dart';
import 'package:core/domain/model/expense_template_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/expense_template/expense_template_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The real `ExpenseTemplatePref` runs against the in-memory SharedPreferences,
/// so the tests cover the json round trip as well as the bloc.
Future<ExpenseTemplatePref> buildPref(Map<String, Object> initialValues) async {
  SharedPreferences.setMockInitialValues(initialValues);
  return ExpenseTemplatePref(prefs: await SharedPreferences.getInstance());
}

ExpenseTemplateModel template({String id = "id-1", String note = "coffee"}) =>
    ExpenseTemplateModel(
      id: id,
      note: note,
      price: 25000,
      categoryId: "cat-1",
      categoryName: "needs",
      categoryColor: 0xff443a49,
      subCategoryId: "sub-1",
      subCategoryName: "eat out",
      subCategoryColor: 0xff443a49,
    );

String storedList(List<ExpenseTemplateModel> templates) =>
    jsonEncode(templates.map((item) => item.toJson()).toList());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should emit [Loading, Empty] when nothing was ever saved',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({}),
    act: (bloc) => bloc.add(const GetExpenseTemplateEvent()),
    expect: () => [isA<ExpenseTemplateLoading>(), const ExpenseTemplateEmpty()],
  );

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should emit [Loading, HasData] with the stored templates',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({
      ExpenseTemplatePref.expenseTemplatePref: storedList([template()])
    }),
    act: (bloc) => bloc.add(const GetExpenseTemplateEvent()),
    expect: () =>
        [isA<ExpenseTemplateLoading>(), isA<ExpenseTemplateHasData>()],
    verify: (_) async {
      final stored = await _pref.getTemplates();
      expect(stored.data?.single.note, "coffee");
      expect(stored.data?.single.price, 25000);
      expect(stored.data?.single.subCategoryName, "eat out");
    },
  );

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should persist a new template and flag the change',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({}),
    act: (bloc) => bloc.add(SaveExpenseTemplateEvent(template())),
    expect: () => [isA<ExpenseTemplateHasData>()],
    verify: (_) async {
      final stored = await _pref.getTemplates();
      expect(stored.data?.length, 1);
      expect(stored.data?.single.id, "id-1");
    },
  );

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should replace the template with the same id rather than adding a copy',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({
      ExpenseTemplatePref.expenseTemplatePref: storedList([template()])
    }),
    act: (bloc) =>
        bloc.add(SaveExpenseTemplateEvent(template(note: "iced coffee"))),
    expect: () => [isA<ExpenseTemplateHasData>()],
    verify: (_) async {
      final stored = await _pref.getTemplates();
      expect(stored.data?.length, 1);
      expect(stored.data?.single.note, "iced coffee");
    },
  );

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should refuse a template with an empty name',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({}),
    act: (bloc) => bloc.add(SaveExpenseTemplateEvent(template(note: "  "))),
    expect: () => [isA<ExpenseTemplateError>()],
    verify: (_) async {
      final stored = await _pref.getTemplates();
      expect(stored.data, isEmpty);
    },
  );

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should emit Empty once the last template is deleted',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({
      ExpenseTemplatePref.expenseTemplatePref: storedList([template()])
    }),
    act: (bloc) => bloc.add(const DeleteExpenseTemplateEvent("id-1")),
    expect: () => [const ExpenseTemplateEmpty(isJustChanged: true)],
    verify: (_) async {
      final stored = await _pref.getTemplates();
      expect(stored.data, isEmpty);
    },
  );

  blocTest<ExpenseTemplateBloc, ExpenseTemplateState>(
    'Should keep the other templates when one is deleted',
    build: () => ExpenseTemplateBloc(_pref),
    setUp: () async => _pref = await buildPref({
      ExpenseTemplatePref.expenseTemplatePref:
          storedList([template(), template(id: "id-2", note: "bus fare")])
    }),
    act: (bloc) => bloc.add(const DeleteExpenseTemplateEvent("id-1")),
    expect: () => [isA<ExpenseTemplateHasData>()],
    verify: (_) async {
      final stored = await _pref.getTemplates();
      expect(stored.data?.single.note, "bus fare");
    },
  );

  test('Should survive a stored value written by an older build', () async {
    final pref = await buildPref(
        {ExpenseTemplatePref.expenseTemplatePref: '[{"note":"legacy"}]'});

    final stored = await pref.getTemplates();

    expect(stored.data?.single.note, "legacy");
    expect(stored.data?.single.price, 0);
    expect(stored.data?.single.categoryId, "");
  });
}

late ExpenseTemplatePref _pref;
