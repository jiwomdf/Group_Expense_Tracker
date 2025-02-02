import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/income/income_cubit.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

class UpdateIncomePage extends StatefulWidget {
  static const String routeName = "/update_income_page";
  const UpdateIncomePage({super.key});

  @override
  State<UpdateIncomePage> createState() => _UpdateIncomePageState();
}

class _UpdateIncomePageState extends State<UpdateIncomePage> {
  String? income;

  @override
  void initState() {
    super.initState();
    context.read<IncomeCubit>().getIncome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: loginScreen(context)),
    );
  }

  Widget loginScreen(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return BlocBuilder<IncomeCubit, IncomeState>(
      builder: (context, state) {
        if (state is IncomeUpdated) {
          context.show("Income Updated to $income");
          Navigator.pop(context);
        } else if (state is IncomeHasData) {
          income = state.income.toString();
        }

        return content(formKey, context);
      },
    );
  }

  Padding content(GlobalKey<FormState> formKey, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Update Income",
                          style: TextUtil(context).urbanist(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text("You can update your new income here",
                        style: TextUtil(context).urbanist(
                          fontSize: 16,
                        )),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 10),
                    child: TextFormField(
                      initialValue: income.toString(),
                      keyboardType: TextInputType.number,
                      decoration: textFormFieldStyle(
                          context: context, hintText: "Enter your income here"),
                      validator: (String? val) => (val?.isEmpty ?? true)
                          ? "Income cannot be empty"
                          : null,
                      onChanged: (val) {
                        setState(() {
                          income = val;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() == true) {}
                          },
                          child: Text("Update Income",
                              style: TextUtil(context).urbanist(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
