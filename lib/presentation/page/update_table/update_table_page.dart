import 'package:core/domain/model/expense_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/scheme/update_expense_scheme.dart';

class UpdateTablePage extends StatefulWidget {
  static const routeName = '/update-table';
  const UpdateTablePage({super.key});

  @override
  State<UpdateTablePage> createState() => _UpdateTablePageState();
}

class _UpdateTablePageState extends State<UpdateTablePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Collection Scheme")),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            expenseScheme(),
            categoryScheme(),
            subCategoryScheme(),
          ],
        ),
      )),
    );
  }

  BlocBuilder<ExpenseBloc, ExpenseState> expenseScheme() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(builder: (context, state) {
      if (state is ExpenseInitiated) {
      } else if (state is ExpenseLoading) {
        return const Row();
      } else if (state is ExpenseHasData) {
        updateRow(state.result);
        //context.read<ExpenseBloc>().add(const ResetExpenseEvent());
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
            child: Text(
                "You can update scheme objects in the Firestore collection by modifying the content of the func() in lib/util/scheme/ classes",
                textAlign: TextAlign.center,
                style: TextUtil(context)
                    .urbanist(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding:
                const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
            child: Column(
              children: [
                Text(
                  S.of(context).clickTheUpdateAllExpenseButtonToUpdateEachTable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      context
                          .read<ExpenseBloc>()
                          .add(const GetAllExpenseEvent());
                    },
                    child: Text(S.of(context).updateAllExpense),
                  ),
                ),
              ],
            ),
          )
        ],
      );
    });
  }

  updateRow(List<ExpenseCategoryModel> result) async {
    List<Map<String, dynamic>> newListOfExpense = [];
    for (var i = 0; i < result.length; i++) {
      var action = result[i];
      await Future.delayed(const Duration(milliseconds: 100));
      var updateData =
          UpdateExpenseScheme.updateExpenseSchemeCollection(action);
      newListOfExpense.add(updateData);
    }
    if (mounted) {
      context
          .read<ExpenseBloc>()
          .add(UpdateBatchExpenseEvent(newListOfExpense));
    }
  }

  Widget categoryScheme() {
    return const Padding(
      padding: EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
      child: Column(
        children: [
          Text(
            "click the Update all category button to update each table scheme",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null
              /**TODO: update category scheme*/
              ,
              child: Text("Update all category"),
            ),
          ),
        ],
      ),
    );
  }

  Widget subCategoryScheme() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
      child: Column(
        children: [
          const Text(
            "click the Update all subCategory button to update each table scheme",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null /**TODO: update subCategory scheme*/,
              child: Text(S.of(context).updateAllSubcategory),
            ),
          ),
        ],
      ),
    );
  }
}
