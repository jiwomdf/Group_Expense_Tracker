import 'package:core/domain/model/expense_category_model.dart';
import 'package:core/domain/model/pie_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/util/ext/color_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/list_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';
import 'package:shimmer/shimmer.dart';

class PieChartSubCategoryWidget extends StatefulWidget {
  const PieChartSubCategoryWidget({super.key});

  @override
  State<PieChartSubCategoryWidget> createState() =>
      _PieChartSubCategoryWidgetState();
}

class _PieChartSubCategoryWidgetState extends State<PieChartSubCategoryWidget> {
  var _touchedIndex = double.maxFinite;
  List<ExpenseCategoryModel> listExpense = [];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(builder: (context, state) {
      if (state is ExpenseInitiated) {
        return const Row();
      } else if (state is ExpenseLoading) {
        return showPieShimmer();
      } else if (state is ExpenseHasData) {
        listExpense = state.result;
      }

      return Column(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      var pieTouchIdx =
                          pieTouchResponse?.touchedSection?.touchedSectionIndex;
                      if (pieTouchIdx == null) return;
                      _touchedIndex = pieTouchIdx.toDouble();
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: showingSections(listExpense),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Text(S.of(context).category,
                  style: TextUtil(context)
                      .urbanist(fontSize: 14, fontWeight: FontWeight.bold)))
        ],
      );
    });
  }

  List<PieChartSectionData> showingSections(
      List<ExpenseCategoryModel> listExpense) {
    List<PieChartSectionData> expenses = [];
    List<PieModel> tempExpenseList = [];

    var sortExpenseList =
        listExpense.sortedBy((it) => it.subCategoryName).toList();

    var tempCategory = "";
    for (var i = 0; i < sortExpenseList.length; i++) {
      var data = sortExpenseList[i];

      if (tempCategory != data.subCategoryName) {
        var tempTotalCategory = 0;
        var tempList = sortExpenseList
            .where((it) => it.subCategoryName == data.subCategoryName);

        for (var item in tempList) {
          tempTotalCategory += item.price;
        }

        tempExpenseList.add(
          PieModel(
            name: data.subCategoryName,
            color: data.subCategoryColor,
            total: tempTotalCategory,
          ),
        );
        tempCategory = data.subCategoryName;
        tempTotalCategory = 0;
      }
    }

    for (var i = 0; i < tempExpenseList.length; i++) {
      var data = tempExpenseList[i];
      final isTouched =
          (i == _touchedIndex) && (_touchedIndex != double.maxFinite);
      final fontSize = isTouched ? 16.0 : 14.0;
      final fontWeight = isTouched ? FontWeight.bold : FontWeight.w500;
      final radius = isTouched ? 16.0 : 14.0;
      final title =
          isTouched ? "${data.name} Rp. ${data.total.toRupiah()}" : data.name;
      final color =
          isTouched ? darken(Theme.of(context).cardColor) : Color(data.color);

      expenses.add(PieChartSectionData(
        color: color,
        title: title,
        radius: radius,
        value: data.total.toDouble(),
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
      ));
    }
    return expenses;
  }

  Widget showPieShimmer() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).cardColor,
      highlightColor: darken(Theme.of(context).cardColor, .05),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: AppColors.black.primary,
                ),
                height: 100,
                width: 100),
          ),
        ],
      ),
    );
  }
}
