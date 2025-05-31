import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/app/apps/app_home.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/expense_form_page.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/card_expense_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/card_income_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/list_expense/expense_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/pie_chart_sub_category_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/pie_chart_widget.dart';
import 'package:group_expense_tracker/presentation/widget/filter_widget.dart';
import 'package:group_expense_tracker/presentation/widget/right_drawer.dart';
import 'package:group_expense_tracker/presentation/widget/toolbar.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home-page';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int ddlMonth = DateTime.now().month;
  int ddlYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();

    if (mounted) {
      final appHome = AppHome.of(context);
      final isDarkMode = appHome.getIsDarkMode();
      Future.microtask(() => isDarkMode).then((value) {
        _setTheme(appHome, !value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => di.locator<SubcategoryBloc>()
              ..add(const GetSubcategoryWithCacheEvent())),
        BlocProvider(
            create: (_) => di.locator<ExpenseBloc>()
              ..add(GetExpenseEvent(
                  DateTime.now().month, DateTime.now().year, ""))),
      ],
      child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: Toolbar(title: S.of(context).home, showDrawer: true),
            endDrawer: const RightDrawer(),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                          top: 12, left: 16, right: 16, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PieChartSubCategoryWidget(),
                          PieChartWidget(),
                        ],
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CardExpenseWidget(),
                            CardIncomeWidget(),
                          ],
                        )),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 15, left: 16, right: 16),
                      child: Column(
                        children: [
                          FilterWidget(
                            ddlMonth: ddlMonth,
                            ddlYear: ddlYear,
                            onDdlChanged: (month, year, ddlSubCategory,
                                ddlSubCategoryId) {
                              context.read<ExpenseBloc>().add(GetExpenseEvent(
                                  month, year, ddlSubCategoryId));
                              setState(() {
                                ddlMonth = month;
                                ddlYear = year;
                                ddlSubCategory = ddlSubCategory;
                              });
                            },
                          ),
                          const ExpenseWidget(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "fab_insert",
                  shape: const CircleBorder(),
                  onPressed: () {
                    Navigator.pushNamed(context, ExpenseFormPage.routeName)
                        .then((note) {
                      if (context.mounted) {
                        if (note != null && note != "") {
                          context.show(
                            "$note ${S.of(context).hasBeenModifiedDataNotShowedYetInorderToSave}",
                          );
                        }
                        context
                            .read<ExpenseBloc>()
                            .add(const ResetExpenseEvent());
                      }
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _setTheme(AppHomeState appHome, bool value) {
    if (value) {
      appHome.changeTheme(ThemeMode.light);
    } else {
      appHome.changeTheme(ThemeMode.dark);
    }
  }
}
