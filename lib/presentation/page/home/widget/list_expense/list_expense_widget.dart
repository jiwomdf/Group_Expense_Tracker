import 'package:core/domain/model/expense_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/expense_form_page.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

//ignore: must_be_immutable
class ListExpenseWidget extends StatefulWidget {
  List<ExpenseCategoryModel> expenseCategoryModel = [];
  ListExpenseWidget({super.key, required this.expenseCategoryModel});

  @override
  State<ListExpenseWidget> createState() => _ListExpenseWidgetState();
}

class _ListExpenseWidgetState extends State<ListExpenseWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).date),
            Text(S.of(context).name),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(S.of(context).category),
            ),
            Text(S.of(context).price)
          ],
        ),
        ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.expenseCategoryModel.length,
            itemBuilder: (context, index) {
              return expenseItem(widget.expenseCategoryModel[index]);
            }),
      ],
    );
  }

  Widget expenseItem(ExpenseCategoryModel expenseCategoryModel) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              ExpenseFormPage.routeName,
              arguments: expenseCategoryModel,
            ).then((note) {
              if (mounted) {
                if (note != null && note != "") {
                  context.show(
                    "$note ${S.of(context).hasBeenModifiedDataNotShowedYetInorderToSave}",
                  );
                }
                context.read<ExpenseBloc>().add(const ResetExpenseEvent());
              }
            }),
            child: Container(
              padding: const EdgeInsets.only(left: 4, right: 4),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: Theme.of(context).cardColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  date(expenseCategoryModel),
                  expenseName(expenseCategoryModel),
                  subCategory(expenseCategoryModel),
                  price(expenseCategoryModel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Expanded price(ExpenseCategoryModel expenseCategoryModel) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              "Rp ${expenseCategoryModel.price.toRupiah()}",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: expenseCategoryModel.categoryColor.toColor(),
            ),
            child: Text(
              expenseCategoryModel.categoryName,
              overflow: TextOverflow.fade,
              maxLines: 1,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Expanded subCategory(ExpenseCategoryModel expenseCategoryModel) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: expenseCategoryModel.subCategoryColor.toColor(),
        ),
        child: Text(
          expenseCategoryModel.subCategoryName,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Expanded expenseName(ExpenseCategoryModel expenseCategoryModel) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expenseCategoryModel.note),
          ],
        ),
      ),
    );
  }

  Expanded date(ExpenseCategoryModel expenseCategoryModel) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, right: 10, bottom: 10),
        child: Text(expenseCategoryModel.date
                .toDateGlobalFormat()
                ?.toDateString(DateFormatUtil.ddMMMyyyy) ??
            ""),
      ),
    );
  }
}
