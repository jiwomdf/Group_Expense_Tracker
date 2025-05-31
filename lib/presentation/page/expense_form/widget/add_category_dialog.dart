import 'package:core/domain/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:group_expense_tracker/presentation/bloc/category/category_bloc.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';
import 'package:uuid/uuid.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final CategoryModel _ddlValue = CategoryModel(
    categoryId: "",
    categoryColor: 0xff443a49,
    categoryName: "",
  );
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryUpdated) {
          context.show("Type Inserted");
          Navigator.of(context, rootNavigator: true).pop(_ddlValue);
        } else if (state is CategoryError) {
          context.show(state.message);
        }

        return initDialogWidget();
      },
    );
  }

  Widget initDialogWidget() {
    return Dialog(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Column(
                    children: [
                      Text('Add Type',
                          style: TextUtil(context).urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          )),
                      const Text(
                          "(Type is the parent of categories. eg: Primary needs, Secondary needs)",
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "Type name.."),
                    validator: (val) =>
                        (val?.isEmpty ?? true) ? 'Type cannot be empty' : null,
                    onChanged: (val) {
                      setState(
                          () => _ddlValue.categoryName = val.toLowerCase());
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: BlockPicker(
                    pickerColor: Color(_ddlValue.categoryColor),
                    onColorChanged: (color) {
                      setState(
                          () => _ddlValue.categoryColor = color.toARGB32());
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.pink,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context
                              .read<CategoryBloc>()
                              .add(UpdateCategoryEvent(CategoryModel(
                                categoryId: const Uuid().v4(),
                                categoryName:
                                    _ddlValue.categoryName.toLowerCase(),
                                categoryColor: _ddlValue.categoryColor,
                              )));
                        }
                      },
                      child: const Text('Insert'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
