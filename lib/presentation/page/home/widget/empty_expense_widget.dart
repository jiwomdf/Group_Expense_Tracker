import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_assets_util.dart';

/// Shown on the dashboard when the selected month has no expenses.
///
/// Replaces the charts and total cards rather than sitting under them: an empty
/// pie chart next to "Rp 0" reads as a broken screen, while this reads as a
/// deliberate starting point.
class EmptyExpenseWidget extends StatelessWidget {
  /// Opens the expense form. The dashboard passes the same handler its add
  /// button uses.
  final VoidCallback onAddExpense;

  const EmptyExpenseWidget({super.key, required this.onAddExpense});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 24, right: 24, bottom: 24),
      child: Column(
        children: [
          SvgPicture.asset(AppAssetsUtil.imgFinancial, height: 180),
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text(
              S.of(context).noRecordYetPleaseCreateOne,
              textAlign: TextAlign.center,
              style: TextUtil(context).urbanist(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Add your first expense for this month, or pick another month above.",
              textAlign: TextAlign.center,
              style: TextUtil(context).urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add),
                label: const Text("Add expense"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
