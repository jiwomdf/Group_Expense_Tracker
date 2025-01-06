import 'dart:html' as universal_html;

import 'package:core/domain/model/expense_category_model.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:group_expense_tracker/generated/l10n.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_assets_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

class ExportExpenseSheetPage extends StatefulWidget {
  static const routeName = '/export-expense-sheet-page';

  const ExportExpenseSheetPage({super.key});

  @override
  State<ExportExpenseSheetPage> createState() => _ExportExpenseSheetPageState();
}

class _ExportExpenseSheetPageState extends State<ExportExpenseSheetPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).exportExpenseAsSpreadSheet),
        ),
        body: BlocBuilder<ExpenseBloc, ExpenseState>(builder: (context, state) {
          if (state is ExpenseInitiated) {
          } else if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ExpenseHasData) {
            createSheet(state.result);
            context.read<ExpenseBloc>().add(const ResetExpenseEvent());
          }

          return Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S.of(context).exportExpenseDataToSpreadsheet,
                      style: TextUtil(context)
                          .urbanist(fontSize: 18, fontWeight: FontWeight.w500)),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                        S
                            .of(context)
                            .easilyTrackAndManageYourExpensesWithOurExportTo,
                        style: TextUtil(context).urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(AppAssetsUtil.imgSpreadSheet,
                      height: 200),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: Text(S.of(context).downloadSpreadSheet),
                      onPressed: () {
                        if (kIsWeb) {
                          context
                              .read<ExpenseBloc>()
                              .add(const GetAllExpenseEvent());
                        } else {
                          context.show(
                              S.of(context).theFeatureCurrentlyOnlyWorksOnWeb);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }));
  }

  Future<void> createSheet(List<ExpenseCategoryModel> listData) async {
    // Create a new Excel file
    var excel = Excel.createExcel();

    // Add data to the first sheet (default name is "Sheet1")
    Sheet sheet = excel['group_expense_sheet_${DateTime.now().year}'];

    // Add the header row
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Name'),
      TextCellValue('Category'),
      TextCellValue('Price'),
      TextCellValue('Parent Category'),
      TextCellValue('Email'),
      TextCellValue('TimeStamp'),
      TextCellValue('Status'),
      TextCellValue('Year'),
      TextCellValue('Month'),
      TextCellValue('day'),
    ]);

    for (var data in listData) {
      sheet.appendRow([
        DateCellValue.fromDateTime(data.date.toDateGlobalFormat() ??
            DateTime.fromMillisecondsSinceEpoch(0)),
        TextCellValue(data.note),
        TextCellValue(data.subCategoryName),
        IntCellValue(data.price),
        TextCellValue(data.categoryName),
        TextCellValue(data.email),
        TextCellValue(data.timeStamp),
        TextCellValue(data.status),
        IntCellValue(int.tryParse(data.year) ?? 0),
        IntCellValue(int.tryParse(data.month) ?? 0),
        IntCellValue(int.tryParse(data.dayOfMonth) ?? 0),
      ]);
    }

    List<int>? excelBytes = excel.encode();

    if (excelBytes != null) {
      universal_html.AnchorElement()
        ..href = '${Uri.dataFromBytes(
          excelBytes,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // MIME type for Excel files
        )}'
        ..download =
            "group_expense_tracker_${DateTime.now().toDateString("yyyy-MM-dd")}.xlsx"
        ..style.display = 'none'
        ..click();
    }
  }
}
