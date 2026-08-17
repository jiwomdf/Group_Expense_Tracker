part of 'expense_template_bloc.dart';

sealed class ExpenseTemplateEvent extends Equatable {
  const ExpenseTemplateEvent();

  @override
  List<Object> get props => [];
}

class GetExpenseTemplateEvent extends ExpenseTemplateEvent {
  const GetExpenseTemplateEvent();
}

/// Adds the template, or replaces the stored one with the same id.
class SaveExpenseTemplateEvent extends ExpenseTemplateEvent {
  final ExpenseTemplateModel template;

  const SaveExpenseTemplateEvent(this.template);

  @override
  List<Object> get props => [template.id, template.note, template.price];
}

class DeleteExpenseTemplateEvent extends ExpenseTemplateEvent {
  final String id;

  const DeleteExpenseTemplateEvent(this.id);

  @override
  List<Object> get props => [id];
}
