import 'package:core/domain/model/expense_template_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/presentation/bloc/expense_template/expense_template_bloc.dart';
import 'package:group_expense_tracker/presentation/page/expense_template/expense_template_page.dart';
import 'package:group_expense_tracker/presentation/page/expense_template/widget/expense_template_tile.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';

/// Lets the user pick saved templates to fill the expense form with. Returns
/// what they chose, or null when they closed the sheet without picking.
///
/// Several can be chosen at once, since a daily shop is usually the same handful
/// of items, and each one becomes its own row.
Future<List<ExpenseTemplateModel>?> pickExpenseTemplates(BuildContext context) {
  return showModalBottomSheet<List<ExpenseTemplateModel>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (_) => di.locator<ExpenseTemplateBloc>()
        ..add(const GetExpenseTemplateEvent()),
      child: const _PickTemplateSheet(),
    ),
  );
}

class _PickTemplateSheet extends StatefulWidget {
  const _PickTemplateSheet();

  @override
  State<_PickTemplateSheet> createState() => _PickTemplateSheetState();
}

class _PickTemplateSheetState extends State<_PickTemplateSheet> {
  /// Ids rather than models: the list is re-emitted on every state change, so
  /// the objects are not the same instances the user tapped.
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        // Leaves the form visible behind the sheet rather than covering the
        // whole screen for what is usually a short list.
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: BlocBuilder<ExpenseTemplateBloc, ExpenseTemplateState>(
          builder: (context, state) {
            if (state is ExpenseTemplateLoading) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final templates = state is ExpenseTemplateHasData
                ? state.result
                : const <ExpenseTemplateModel>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text("Fill from template",
                      style: TextUtil(context)
                          .urbanist(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                if (templates.isEmpty)
                  _empty(context)
                else ...[
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final template in templates)
                          ExpenseTemplateTile(
                            template: template,
                            onTap: () => _toggle(template.id),
                            trailing: Checkbox(
                              value: _selectedIds.contains(template.id),
                              onChanged: (_) => _toggle(template.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _actions(context, templates),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, List<ExpenseTemplateModel> templates) {
    final selected = templates
        .where((template) => _selectedIds.contains(template.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          // Nothing ticked means nothing to fill, so the button stays disabled
          // rather than closing the sheet with no effect.
          onPressed: selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(selected),
          child: Text(selected.length <= 1
              ? "Fill form"
              : "Fill form with ${selected.length} items"),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("No templates saved yet.",
              style: TextUtil(context).plusJakarta(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
              "Save the expenses you fill in every day, then pick them here to fill the form.",
              style: TextUtil(context)
                  .plusJakarta(fontSize: 12, color: AppColors.grey.lightGray)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // The navigator is captured first, then the sheet is closed:
                // this context is gone once its route is popped.
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pushNamed(ExpenseTemplatePage.routeName);
              },
              icon: const Icon(Icons.add),
              label: const Text("Manage templates"),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }
}
