import 'package:core/domain/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/presentation/bloc/category/category_bloc.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/string_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';

class CategoryDdlWidget extends StatefulWidget {
  final CategoryModel? initialData;
  final ValueChanged<CategoryModel> selectedCategory;

  const CategoryDdlWidget({
    super.key,
    required this.initialData,
    required this.selectedCategory,
  });

  @override
  State<CategoryDdlWidget> createState() => _CategoryDdlWidgetState();
}

class _CategoryDdlWidgetState extends State<CategoryDdlWidget> {
  List<CategoryModel> _categories = CategoryModel.emptyList();
  CategoryModel _ddlValue = CategoryModel(
    categoryId: "",
    categoryColor: 0xff443a49,
    categoryName: "",
  );

  @override
  void initState() {
    _ddlValue = widget.initialData ??
        CategoryModel(
          categoryId: "",
          categoryColor: 0xff443a49,
          categoryName: "",
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.locator<CategoryBloc>()..add(const GetCategoryEvent()),
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryHasData) {
            _categories = state.result;
          } else if (state is CategoryError) {
            context.show(state.message);
          }

          return DropdownButton(
            hint: Row(
              children: [
                SizedBox(
                  height: 15,
                  child: CircleAvatar(
                      backgroundColor: _ddlValue.categoryColor.toColor()),
                ),
                Text((_ddlValue.categoryName).ifEmpty("Choose one")),
              ],
            ),
            items: _categories.map((CategoryModel value) {
              return DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 15,
                        child: CircleAvatar(
                            backgroundColor: value.categoryColor.toColor()),
                      ),
                      Text(value.categoryName),
                    ],
                  ));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _ddlValue.categoryId = value?.categoryId ?? "";
                _ddlValue.categoryName = value?.categoryName ?? "";
                _ddlValue.categoryColor = value?.categoryColor ?? 0;
              });
              widget.selectedCategory(_ddlValue);
            },
          );
        },
      ),
    );
  }
}
