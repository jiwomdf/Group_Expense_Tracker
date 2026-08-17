import 'package:bloc/bloc.dart';
import 'package:core/data/pref/expense_template_pref.dart';
import 'package:core/domain/model/expense_template_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'expense_template_event.dart';
part 'expense_template_state.dart';

/// Owns the saved expense templates. Every write returns the new list, so the
/// page renders straight from the emitted state without re-reading prefs.
class ExpenseTemplateBloc
    extends Bloc<ExpenseTemplateEvent, ExpenseTemplateState> {
  final ExpenseTemplatePref _templatePref;

  ExpenseTemplateBloc(this._templatePref) : super(ExpenseTemplateLoading()) {
    on<GetExpenseTemplateEvent>((event, emit) async {
      emit(ExpenseTemplateLoading());
      _emitResult(emit, await _templatePref.getTemplates());
    });

    on<SaveExpenseTemplateEvent>((event, emit) async {
      _emitResult(emit, await _templatePref.saveTemplate(event.template),
          isJustChanged: true);
    });

    on<DeleteExpenseTemplateEvent>((event, emit) async {
      _emitResult(emit, await _templatePref.deleteTemplate(event.id),
          isJustChanged: true);
    });
  }

  /// An empty list is its own state: the page shows a "no templates yet" call to
  /// action rather than a blank screen.
  void _emitResult(
    Emitter<ExpenseTemplateState> emit,
    ResourceUtil<List<ExpenseTemplateModel>> result, {
    bool isJustChanged = false,
  }) {
    switch (result.status) {
      case Status.success:
        final templates = result.data ?? const <ExpenseTemplateModel>[];
        emit(templates.isEmpty
            ? ExpenseTemplateEmpty(isJustChanged: isJustChanged)
            : ExpenseTemplateHasData(templates, isJustChanged: isJustChanged));
        break;
      case Status.error:
        emit(ExpenseTemplateError(result.failure?.message ?? ""));
        break;
    }
  }
}
