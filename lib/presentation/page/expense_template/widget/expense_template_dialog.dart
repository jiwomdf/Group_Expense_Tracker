import 'package:core/domain/model/category_model.dart';
import 'package:core/domain/model/expense_template_model.dart';
import 'package:core/domain/model/sub_category_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/string_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Creates or edits one template. Returns the edited [ExpenseTemplateModel] on
/// save, or null when the user backs out.
///
/// The lookup lists are passed in rather than fetched here: the page above
/// already holds them, and a dialog opened on the root navigator would not see
/// its blocs anyway.
class ExpenseTemplateDialog extends StatefulWidget {
  /// The template being edited, or null when adding a new one.
  final ExpenseTemplateModel? template;

  final List<CategoryModel> categories;
  final List<SubCategoryModel> subCategories;

  const ExpenseTemplateDialog({
    super.key,
    this.template,
    required this.categories,
    required this.subCategories,
  });

  @override
  State<ExpenseTemplateDialog> createState() => _ExpenseTemplateDialogState();
}

class _ExpenseTemplateDialogState extends State<ExpenseTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _priceController = TextEditingController();

  CategoryModel? _category;
  SubCategoryModel? _subCategory;

  final NumberFormat _formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  bool get _isEdit => widget.template != null;

  @override
  void initState() {
    super.initState();

    final template = widget.template;
    if (template == null) return;

    _noteController.text = template.note;
    // A template may carry no price, in which case the field stays empty rather
    // than showing a meaningless zero.
    if (template.price > 0) {
      _priceController.text = _formatter.format(template.price);
    }

    // Matched by id against the current lists, so a renamed or recoloured
    // category shows its up-to-date form instead of the copy saved with the
    // template.
    _category = widget.categories.cast<CategoryModel?>().firstWhere(
          (item) => item?.categoryId == template.categoryId,
          orElse: () => null,
        );
    _subCategory = widget.subCategories.cast<SubCategoryModel?>().firstWhere(
          (item) => item?.subCategoryId == template.subCategoryId,
          orElse: () => null,
        );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // Held to the page background rather than material 3's tinted dialog
      // surface, so it reads the same as the expense form behind it.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(_isEdit ? 'Edit Template' : 'Add Template',
                      style: TextUtil(context).urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                      "Saved on this device, so you can fill the expense form with one tap.",
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center),
                ),
                TextFormField(
                  controller: _noteController,
                  decoration: textFormFieldStyle(
                      context: context, hintText: "Expense Name.."),
                  validator: (val) => (val?.trim().isEmpty ?? true)
                      ? "Name cannot be empty"
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  // Same reason as the expense form: the live formatter behaves
                  // differently on the web build.
                  inputFormatters: kIsWeb ? null : [textInputFormatter()],
                  keyboardType: TextInputType.number,
                  decoration: textFormFieldStyle(
                          context: context, hintText: "Price (optional)..")
                      .copyWith(icon: const Text("Rp ")),
                  // Left blank on purpose means "ask me every time", so only a
                  // filled-in price is checked.
                  validator: (val) {
                    final price = val?.fromRupiah() ?? 0;
                    if ((val ?? "").trim().isEmpty || price == 0) return null;
                    return price < 100
                        ? "Price should be greater than Rp 100"
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                _categoryDdl(),
                const SizedBox(height: 8),
                _subCategoryDdl(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.pink),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: _save,
                      child: Text(_isEdit ? 'Save' : 'Add'),
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

  Widget _categoryDdl() {
    return DropdownButton<CategoryModel>(
      value: _category,
      hint: const Text("Type"),
      isExpanded: true,
      items: widget.categories
          .map((item) => DropdownMenuItem(
                value: item,
                child: _ddlItem(item.categoryName, item.categoryColor),
              ))
          .toList(),
      onChanged: (value) => setState(() => _category = value),
    );
  }

  Widget _subCategoryDdl() {
    return DropdownButton<SubCategoryModel>(
      value: _subCategory,
      hint: const Text("Category"),
      isExpanded: true,
      items: widget.subCategories
          .map((item) => DropdownMenuItem(
                value: item,
                child: _ddlItem(item.subCategoryName, item.subCategoryColor),
              ))
          .toList(),
      onChanged: (value) => setState(() => _subCategory = value),
    );
  }

  Widget _ddlItem(String name, int color) {
    return Row(
      children: [
        SizedBox(
          height: 15,
          child: CircleAvatar(backgroundColor: color.toColor()),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Type and category are required: the whole point of a template is that the
    // filled row needs no further picking.
    if (_category == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Type is empty")));
      return;
    }
    if (_subCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Category is empty")));
      return;
    }

    Navigator.of(context).pop(ExpenseTemplateModel(
      // Editing keeps the id so the store replaces the entry instead of adding
      // a second copy.
      id: widget.template?.id ?? const Uuid().v4(),
      note: _noteController.text.trim(),
      price: _priceController.text.fromRupiah(),
      categoryId: _category?.categoryId ?? "",
      categoryName: _category?.categoryName ?? "",
      categoryColor: _category?.categoryColor ?? 0xff443a49,
      subCategoryId: _subCategory?.subCategoryId ?? "",
      subCategoryName: _subCategory?.subCategoryName ?? "",
      subCategoryColor: _subCategory?.subCategoryColor ?? 0xff443a49,
    ));
  }
}
