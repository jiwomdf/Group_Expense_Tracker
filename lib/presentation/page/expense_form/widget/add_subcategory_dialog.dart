import 'package:core/domain/model/sub_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';
import 'package:uuid/uuid.dart';

class AddSubCategoryDialog extends StatefulWidget {
  const AddSubCategoryDialog({super.key});

  @override
  State<AddSubCategoryDialog> createState() => _AddSubCategoryDialogState();
}

class _AddSubCategoryDialogState extends State<AddSubCategoryDialog> {
  final SubCategoryModel _ddlValue = SubCategoryModel(
    subCategoryId: "",
    subCategoryColor: 0xff443a49,
    subCategoryName: "",
  );
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubcategoryBloc, SubcategoryState>(
      builder: (context, state) {
        if (state is SubcategoryUpdated) {
          context.show("Category Inserted");
          Navigator.of(context, rootNavigator: true).pop(_ddlValue);
        } else if (state is SubcategoryError) {
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
                  child: Text('Add Category',
                      style: TextUtil(context).urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("Choose color",
                            style: TextUtil(context).plusJakarta(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      ColorPicker(
                        enableAlpha: false,
                        displayThumbColor: false,
                        hexInputBar: false,
                        pickerColor: Color(_ddlValue.subCategoryColor),
                        onColorChanged: (color) {
                          setState(
                              () => _ddlValue.subCategoryColor = color.value);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: textFormFieldStyle(
                        context: context, hintText: "Category name.."),
                    validator: (val) => (val?.isEmpty ?? true)
                        ? 'Category cannot be empty'
                        : null,
                    onChanged: (val) {
                      setState(
                          () => _ddlValue.subCategoryName = val.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.pink),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context
                              .read<SubcategoryBloc>()
                              .add(UpdateSubcategoryEvent(SubCategoryModel(
                                subCategoryId: const Uuid().v4(),
                                subCategoryName:
                                    _ddlValue.subCategoryName.toLowerCase(),
                                subCategoryColor: _ddlValue.subCategoryColor,
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
