import 'package:core/domain/model/category_model.dart';
import 'package:core/domain/model/expense_template_model.dart';
import 'package:core/domain/model/sub_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/presentation/bloc/category/category_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/expense_template/expense_template_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/page/expense_template/widget/expense_template_dialog.dart';
import 'package:group_expense_tracker/presentation/page/expense_template/widget/expense_template_tile.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

/// Manages the list of expenses the user enters daily, so the expense form can
/// be filled from it instead of typed out each time.
///
/// The templates are stored on the device only, like the monthly budget.
class ExpenseTemplatePage extends StatelessWidget {
  static const routeName = '/expense-template-page';

  const ExpenseTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => di.locator<ExpenseTemplateBloc>()
              ..add(const GetExpenseTemplateEvent())),
        // The add/edit dialog picks a type and category from these, so they are
        // fetched once here and handed down.
        BlocProvider(
            create: (_) =>
                di.locator<CategoryBloc>()..add(const GetCategoryEvent())),
        BlocProvider(
            create: (_) => di.locator<SubcategoryBloc>()
              ..add(const GetSubcategoryEvent())),
      ],
      child: const _ExpenseTemplateView(),
    );
  }
}

class _ExpenseTemplateView extends StatelessWidget {
  const _ExpenseTemplateView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Templates"),
        // Same as the expense form: material 3 would otherwise tint the bar
        // from the seed colour and leave it darker than the page under it.
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab_add_template",
        shape: const CircleBorder(),
        onPressed: () => _openDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: BlocConsumer<ExpenseTemplateBloc, ExpenseTemplateState>(
          listener: (context, state) {
            if (state is ExpenseTemplateError) {
              context.show(state.message);
            }
          },
          builder: (context, state) {
            if (state is ExpenseTemplateLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final templates = state is ExpenseTemplateHasData
                ? state.result
                : const <ExpenseTemplateModel>[];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Items you buy every day. Pick them on the expense form and the rows are filled in for you.",
                        textAlign: TextAlign.justify,
                        style: TextUtil(context).plusJakarta(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    if (templates.isEmpty)
                      _empty(context)
                    else
                      for (final template in templates)
                        ExpenseTemplateTile(
                          template: template,
                          onTap: () => _openDialog(context, template: template),
                          trailing: IconButton(
                            tooltip: "Delete template",
                            icon: Icon(Icons.delete_outline,
                                color: AppColors.red.primary),
                            onPressed: () => _confirmDelete(context, template),
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.bookmark_border,
              size: 48, color: AppColors.grey.lightGray),
          const SizedBox(height: 12),
          Text("No templates yet",
              style: TextUtil(context)
                  .plusJakarta(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text("Add the expenses you fill in every day.",
              style: TextUtil(context).plusJakarta(fontSize: 12)),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: () => _openDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Add template"),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the add/edit dialog and saves what comes back. Shared by the add
  /// button, the empty state and tapping a row.
  Future<void> _openDialog(BuildContext context,
      {ExpenseTemplateModel? template}) async {
    final templateBloc = context.read<ExpenseTemplateBloc>();
    final categoryState = context.read<CategoryBloc>().state;
    final subCategoryState = context.read<SubcategoryBloc>().state;

    final categories = categoryState is CategoryHasData
        ? categoryState.result
        : <CategoryModel>[];
    final subCategories = subCategoryState is SubcategoryHasData
        ? subCategoryState.result
        : <SubCategoryModel>[];

    // A lookup list that has not arrived yet is not the same as an empty one,
    // so a slow fetch does not send the user off to create types they have.
    if (categoryState is CategoryLoading ||
        subCategoryState is SubcategoryLoading) {
      context.show("Still loading types, try again in a moment");
      return;
    }

    // Without a type and a category there is nothing to pre-pick, and both are
    // created from the expense form rather than here.
    if (categories.isEmpty || subCategories.isEmpty) {
      context.show("Add a type and a category from the expense form first");
      return;
    }

    final result = await showDialog<ExpenseTemplateModel>(
      context: context,
      builder: (_) => ExpenseTemplateDialog(
        template: template,
        categories: categories,
        subCategories: subCategories,
      ),
    );

    if (result == null) return;
    templateBloc.add(SaveExpenseTemplateEvent(result));
  }

  Future<void> _confirmDelete(
      BuildContext context, ExpenseTemplateModel template) async {
    final templateBloc = context.read<ExpenseTemplateBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
        title: const Text("Delete template"),
        content: Text("Remove \"${template.note}\" from your templates?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child:
                Text("Delete", style: TextStyle(color: AppColors.red.primary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    templateBloc.add(DeleteExpenseTemplateEvent(template.id));
  }
}
