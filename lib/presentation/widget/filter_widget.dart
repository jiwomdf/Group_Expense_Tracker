import 'package:core/domain/model/sub_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/widget/devider.dart';
import 'package:group_expense_tracker/util/ext/date_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

/// The dashboard owns the selected month, year and subcategory; this widget only
/// renders them and reports changes back. Keeping a second copy here meant the
/// dropdowns fell back to the current month whenever the dashboard rebuilt its
/// children, so they stopped matching the data on screen.
class FilterWidget extends StatefulWidget {
  static const String _defaultSubCategory = "All Category";
  static const String defaultSubCategoryId = "ALL_CATEGORY_ID";

  final int ddlMonth;
  final int ddlYear;
  final String ddlSubCategoryId;
  final Function onDdlChanged;

  const FilterWidget(
      {super.key,
      required this.ddlMonth,
      required this.ddlYear,
      this.ddlSubCategoryId = "",
      required this.onDdlChanged});

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  final List<SubCategoryModel> _subCategoryList = [];

  int get _month =>
      widget.ddlMonth == 0 ? DateTime.now().month : widget.ddlMonth;

  int get _year => widget.ddlYear == 0 ? DateTime.now().year : widget.ddlYear;

  String get _subCategoryId => widget.ddlSubCategoryId.isEmpty
      ? FilterWidget.defaultSubCategoryId
      : widget.ddlSubCategoryId;

  /// The year picker offers the last five years, but a filter can be restored
  /// with an older one, and a dropdown whose value is missing from its items
  /// throws.
  List<int> get _listYear {
    final years = generateLastFiveYear();
    if (!years.contains(_year)) {
      years
        ..add(_year)
        ..sort((a, b) => b.compareTo(a));
    }
    return years;
  }

  SubCategoryModel get _defaultSubCategory => SubCategoryModel(
        subCategoryId: FilterWidget.defaultSubCategoryId,
        subCategoryColor: 0xff443a49,
        subCategoryName: FilterWidget._defaultSubCategory,
      );

  SubCategoryModel get _selectedSubCategory => _subCategoryList.firstWhere(
      (itm) => itm.subCategoryId == _subCategoryId,
      orElse: () => _defaultSubCategory);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          monthDropDown(),
          devider(),
          yearDropDown(),
          devider(),
          categoryDropDown(),
        ],
      ),
    );
  }

  Widget monthDropDown() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).cardColor,
      ),
      child: DropdownButton<int>(
        value: _month,
        items: ddMonths.map((Map<String, int> value) {
          return DropdownMenuItem(
              value: value.values.first, child: Text(value.keys.first));
        }).toList(),
        onChanged: (value) {
          _updateExpenseList(value ?? _month, _year);
        },
      ),
    );
  }

  Widget yearDropDown() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).cardColor,
      ),
      child: DropdownButton<int>(
        value: _year,
        items: _listYear.map((int value) {
          return DropdownMenuItem(value: value, child: Text(value.toString()));
        }).toList(),
        onChanged: (value) {
          _updateExpenseList(_month, value ?? _year);
        },
      ),
    );
  }

  Widget categoryDropDown() {
    return BlocBuilder<SubcategoryBloc, SubcategoryState>(
      builder: (context, state) {
        if (state is SubcategoryHasData) {
          _subCategoryList.clear();
          _subCategoryList.add(_defaultSubCategory);
          _subCategoryList.addAll(state.result);
        } else if (state is SubcategoryError) {
          context.show(state.message);
        }

        final items = _subCategoryList.isEmpty
            ? [_defaultSubCategory]
            : _subCategoryList;

        return DropdownButton<String>(
          value: _selectedSubCategory.subCategoryId,
          items: items.map((SubCategoryModel value) {
            return DropdownMenuItem(
                value: value.subCategoryId,
                child: Row(
                  children: [
                    SizedBox(
                      height: 15,
                      child: CircleAvatar(
                          backgroundColor: value.subCategoryColor.toColor()),
                    ),
                    Text(value.subCategoryName,
                        overflow: TextOverflow.ellipsis),
                  ],
                ));
          }).toList(),
          onChanged: (value) {
            _updateExpenseList(_month, _year,
                subCategoryId: value ?? FilterWidget.defaultSubCategoryId);
          },
        );
      },
    );
  }

  void _updateExpenseList(int month, int year, {String? subCategoryId}) {
    final selectedId = subCategoryId ?? _subCategoryId;
    final selected = _subCategoryList.firstWhere(
        (itm) => itm.subCategoryId == selectedId,
        orElse: () => _defaultSubCategory);

    // "All Category" is the absence of a filter, so it is reported as empty
    // rather than as a subcategory the query could match on.
    final isAllCategory = selected.subCategoryId ==
        FilterWidget.defaultSubCategoryId;

    widget.onDdlChanged(
        month,
        year,
        isAllCategory ? "" : selected.subCategoryName,
        isAllCategory ? "" : selected.subCategoryId);
  }
}
