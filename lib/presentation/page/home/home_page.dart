import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/app/apps/app_home.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/expense_form_page.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/card_expense_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/empty_expense_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/card_income_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/list_expense/expense_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/pie_chart_sub_category_widget.dart';
import 'package:group_expense_tracker/presentation/page/home/widget/pie_chart_widget.dart';
import 'package:group_expense_tracker/presentation/page/receipt_scan/receipt_scan_launcher.dart';
import 'package:group_expense_tracker/presentation/widget/filter_widget.dart';
import 'package:group_expense_tracker/presentation/widget/right_drawer.dart';
import 'package:group_expense_tracker/presentation/widget/toolbar.dart';
import 'package:group_expense_tracker/util/platform_util.dart';

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

    _applyStoredTheme();
  }

  /// Applies the theme saved in prefs once, on the first mount. `changeTheme`
  /// bails out when the mode is unchanged, so this cannot rebuild AppHome in a
  /// loop.
  Future<void> _applyStoredTheme() async {
    final appHome = AppHome.of(context);
    final isDarkMode = await appHome.getIsDarkMode();
    if (!mounted) return;
    _setTheme(appHome, !isDarkMode);
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
            body: SafeArea(child: _dashboardBody(context, state)),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Receipt scanning relies on ML Kit, which is Android/iOS only.
                if (PlatformUtil.isAndroid() || PlatformUtil.isIOS())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FloatingActionButton(
                      heroTag: "fab_scan",
                      shape: const CircleBorder(),
                      onPressed: () => _scanReceipt(context),
                      child: const Icon(Icons.document_scanner_outlined),
                    ),
                  ),
                FloatingActionButton(
                  heroTag: "fab_insert",
                  shape: const CircleBorder(),
                  onPressed: () => _openExpenseForm(context),
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

  /// Charts and total cards are hidden while there is nothing to plot, but the
  /// month filter stays: an empty month is not the same as an empty account, and
  /// the user needs the filter to go looking.
  Widget _dashboardBody(BuildContext context, ExpenseState state) {
    final isEmpty = state is ExpenseEmpty;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (!isEmpty) ...[
            const Padding(
              padding:
                  EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
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
          ],
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 16, right: 16),
            child: Column(
              children: [
                FilterWidget(
                  ddlMonth: ddlMonth,
                  ddlYear: ddlYear,
                  onDdlChanged:
                      (month, year, ddlSubCategory, ddlSubCategoryId) {
                    context
                        .read<ExpenseBloc>()
                        .add(GetExpenseEvent(month, year, ddlSubCategoryId));
                    setState(() {
                      ddlMonth = month;
                      ddlYear = year;
                      ddlSubCategory = ddlSubCategory;
                    });
                  },
                ),
                if (isEmpty)
                  EmptyExpenseWidget(
                      onAddExpense: () => _openExpenseForm(context))
                else
                  const ExpenseWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the expense form and refreshes the dashboard afterwards. Shared by
  /// the add button and the empty state's call to action.
  Future<void> _openExpenseForm(BuildContext context) async {
    final expenseBloc = context.read<ExpenseBloc>();
    final subcategoryBloc = context.read<SubcategoryBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final modifiedMessage =
        S.of(context).hasBeenModifiedDataNotShowedYetInorderToSave;

    final note = await Navigator.pushNamed(context, ExpenseFormPage.routeName);

    if (!mounted) return;
    if (note != null && note != "") {
      messenger.showSnackBar(SnackBar(content: Text("$note $modifiedMessage")));
    }
    expenseBloc.add(const ResetExpenseEvent());
    _reloadSubcategories(subcategoryBloc);
  }

  /// The form can add a subcategory, but this page's SubcategoryBloc is created
  /// once and holds its last result, so the filter dropdown has to be told to
  /// read again on return.
  ///
  /// Costs nothing when nothing was added: the repository only drops its cache
  /// on a write, so this refetches from the network solely when it is stale.
  void _reloadSubcategories(SubcategoryBloc bloc) {
    bloc.add(const GetSubcategoryWithCacheEvent());
  }

  /// Scans a receipt, then hands the result to the expense form so the user can
  /// pick a category and confirm before anything is written.
  Future<void> _scanReceipt(BuildContext context) async {
    // Everything context-derived is captured up front: the two pushes below are
    // async gaps, and this context belongs to the bloc provider rather than to
    // the State, so `mounted` alone would not make it safe to reuse.
    final expenseBloc = context.read<ExpenseBloc>();
    final subcategoryBloc = context.read<SubcategoryBloc>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final modifiedMessage =
        S.of(context).hasBeenModifiedDataNotShowedYetInorderToSave;

    final scan = await openReceiptScanner(context);
    if (scan == null) return;

    final note = await navigator.push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(expenseCategory: null, scannedReceipt: scan),
      ),
    );

    if (!mounted) return;
    if (note != null && note != "") {
      messenger.showSnackBar(SnackBar(content: Text("$note $modifiedMessage")));
    }
    expenseBloc.add(const ResetExpenseEvent());
    _reloadSubcategories(subcategoryBloc);
  }

  void _setTheme(AppHomeState appHome, bool value) {
    if (value) {
      appHome.changeTheme(ThemeMode.light);
    } else {
      appHome.changeTheme(ThemeMode.dark);
    }
  }
}
