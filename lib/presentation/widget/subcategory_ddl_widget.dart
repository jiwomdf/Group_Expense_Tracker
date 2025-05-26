import 'package:core/domain/model/sub_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/string_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

class SubCategoryDdlWidget extends StatefulWidget {
  final SubCategoryModel? _initialData;
  final ValueChanged<SubCategoryModel> selectedCategory;

  const SubCategoryDdlWidget({
    super.key,
    required SubCategoryModel? initialData,
    required this.selectedCategory,
  }) : _initialData = initialData;

  @override
  State<SubCategoryDdlWidget> createState() => _SubCategoryDdlWidgetState();
}

class _SubCategoryDdlWidgetState extends State<SubCategoryDdlWidget> {
  List<SubCategoryModel> _subcategories = SubCategoryModel.emptyList();
  SubCategoryModel _ddlValue = SubCategoryModel(
    subCategoryId: "",
    subCategoryColor: 0xff443a49,
    subCategoryName: "",
  );

  @override
  void initState() {
    _ddlValue = widget._initialData ??
        SubCategoryModel(
          subCategoryId: "",
          subCategoryColor: 0xff443a49,
          subCategoryName: "",
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.locator<SubcategoryBloc>()..add(const GetSubcategoryEvent()),
      child: BlocBuilder<SubcategoryBloc, SubcategoryState>(
        builder: (context, state) {
          if (state is SubcategoryHasData) {
            _subcategories = state.result;
          } else if (state is SubcategoryError) {
            context.show(state.message);
          }

          return DropdownButton(
            hint: Row(
              children: [
                SizedBox(
                  height: 15,
                  child: CircleAvatar(
                      backgroundColor: _ddlValue.subCategoryColor.toColor()),
                ),
                Text((_ddlValue.subCategoryName).ifEmpty("Choose one")),
              ],
            ),
            items: _subcategories.map((SubCategoryModel value) {
              return DropdownMenuItem(
                  value: value,
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
              setState(() {
                _ddlValue.subCategoryId = value?.subCategoryId ?? "";
                _ddlValue.subCategoryName = value?.subCategoryName ?? "";
                _ddlValue.subCategoryColor = value?.subCategoryColor ?? 0;
              });
              widget.selectedCategory(_ddlValue);
            },
          );
        },
      ),
    );
  }
}
