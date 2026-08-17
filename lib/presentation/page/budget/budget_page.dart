import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/presentation/bloc/budget/budget_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/string_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

/// Sets the monthly budget the dashboard measures spending against. The amount
/// is stored on the device only, so it is not shared with the rest of the group.
class BudgetPage extends StatefulWidget {
  static const routeName = '/budget-page';

  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  /// The field is only filled from prefs once, otherwise every rebuild would
  /// overwrite what the user is typing.
  bool _isAmountLoaded = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) =>
                di.locator<BudgetBloc>()..add(const GetBudgetEvent())),
        BlocProvider(
            create: (_) => di.locator<ExpenseBloc>()
              ..add(GetExpenseEvent(now.month, now.year, ""))),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text("Monthly Budget")),
        body: SafeArea(
          child: BlocConsumer<BudgetBloc, BudgetState>(
            listener: (context, state) {
              if (state is BudgetHasData && state.isJustChanged) {
                context.show("Monthly budget saved");
              } else if (state is BudgetNotSet && state.isJustChanged) {
                context.show("Monthly budget removed");
              } else if (state is BudgetError) {
                context.show(state.message);
              }
            },
            builder: (context, state) {
              if (state is BudgetLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final budget = state is BudgetHasData ? state.amount : 0;
              if (!_isAmountLoaded) {
                _amountController.text =
                    budget > 0 ? budget.toRupiah() ?? "" : "";
                _isAmountLoaded = true;
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryCard(context, now, budget),
                      const SizedBox(height: 24),
                      _form(context, budget),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Spending for the current month comes from the same expense bloc the
  /// dashboard uses, so the two can never disagree.
  Widget _summaryCard(BuildContext context, DateTime now, int budget) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        final isLoading = state is ExpenseLoading;
        var spent = 0;
        if (state is ExpenseHasData) {
          for (var expense in state.result) {
            spent += expense.price;
          }
        }

        final remaining = budget - spent;
        final isOverBudget = budget > 0 && remaining < 0;
        final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: Theme.of(context).cardColor,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(now.toDateString("MMMM yyyy") ?? "",
                  style: TextUtil(context)
                      .urbanist(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (isLoading)
                const LinearProgressIndicator()
              else ...[
                Text("Spent Rp. ${spent.toRupiah()}",
                    style: TextUtil(context)
                        .urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (budget > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      color:
                          isOverBudget ? AppColors.red.primary : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      isOverBudget
                          ? "Over budget by Rp. ${(-remaining).toRupiah()}"
                          : "Rp. ${remaining.toRupiah()} left of Rp. ${budget.toRupiah()}",
                      style: TextUtil(context).plusJakarta(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isOverBudget ? AppColors.red.primary : null,
                      )),
                ] else
                  Text("No monthly budget set yet",
                      style: TextUtil(context).plusJakarta(
                          fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _form(BuildContext context, int budget) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Monthly budget",
              style: TextUtil(context)
                  .plusJakarta(fontSize: 16, fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
                "The same amount is used for every month, and it is saved on this device only.",
                textAlign: TextAlign.justify,
                style: TextUtil(context)
                    .plusJakarta(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          TextFormField(
            controller: _amountController,
            // Matches the expense form: the formatter rewrites the field while
            // typing, which the web build handles differently.
            inputFormatters: kIsWeb ? null : [textInputFormatter()],
            keyboardType: TextInputType.number,
            decoration:
                textFormFieldStyle(context: context, hintText: "Budget..")
                    .copyWith(icon: const Text("Rp ")),
            validator: (val) => ((val?.fromRupiah() ?? 0) < 100)
                ? "Budget should be greater than Rp 100"
                : null,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<BudgetBloc>().add(
                          SetBudgetEvent(_amountController.text.fromRupiah()));
                    }
                  },
                  child: const Text("Save Budget")),
            ),
          ),
          if (budget > 0)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                  onPressed: () {
                    _amountController.clear();
                    context.read<BudgetBloc>().add(const ClearBudgetEvent());
                  },
                  child: Text("Remove Budget",
                      style: TextStyle(color: AppColors.red.primary))),
            ),
        ],
      ),
    );
  }
}
