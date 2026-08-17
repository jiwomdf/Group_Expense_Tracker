import 'package:core/data/network/request/insert_expense_request.dart';
import 'package:core/data/network/request/update_expense_request.dart';
import 'package:core/domain/model/category_model.dart';
import 'package:core/domain/model/expense_category_model.dart';
import 'package:core/domain/model/expense_template_model.dart';
import 'package:core/domain/model/receipt_scan_model.dart';
import 'package:core/domain/model/sub_category_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:group_expense_tracker/di/bloc_injection.dart' as di;
import 'package:group_expense_tracker/presentation/bloc/category/category_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/expense/expense_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/fcm/fcm_bloc.dart';
import 'package:group_expense_tracker/presentation/bloc/subcategory/subcategory_bloc.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/widget/add_category_dialog.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/widget/add_subcategory_dialog.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/widget/date_picker_widget.dart';
import 'package:group_expense_tracker/presentation/page/expense_form/widget/pick_template_sheet.dart';
import 'package:group_expense_tracker/presentation/page/expense_template/expense_template_page.dart';
import 'package:group_expense_tracker/presentation/widget/text_form_field.dart';
import 'package:group_expense_tracker/util/ext/date_format_util.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/status_util.dart';
import 'package:group_expense_tracker/util/ext/string_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';
import 'package:group_expense_tracker/util/style/app_snackbar_util.dart';
import 'package:intl/intl.dart';

class ExpenseFormPage extends StatefulWidget {
  static const routeName = '/input-expense-form-page';
  final ExpenseCategoryModel? _expenseCategory;

  /// Values read off a scanned receipt, used to prefill a *new* expense.
  ///
  /// Kept separate from [_expenseCategory] because that field is what marks the
  /// form as editing an existing record.
  final ReceiptScanModel? scannedReceipt;

  const ExpenseFormPage(
      {super.key,
      required ExpenseCategoryModel? expenseCategory,
      this.scannedReceipt})
      : _expenseCategory = expenseCategory;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

/// One editable expense line. Holds its own controllers so rows can be added
/// and removed without the remaining fields losing what the user typed.
class _ExpenseRow {
  final TextEditingController note;
  final TextEditingController price;

  /// Per row, so one receipt can span several types and categories.
  CategoryModel? category;
  SubCategoryModel? subCategory;

  _ExpenseRow({
    String note = "",
    String price = "",
    this.category,
    this.subCategory,
  })  : note = TextEditingController(text: note),
        price = TextEditingController(text: price);

  bool get hasCategory => (category?.categoryId ?? "").isNotEmpty;
  bool get hasSubCategory => (subCategory?.subCategoryId ?? "").isNotEmpty;

  /// Nothing entered anywhere, so the row can be dropped without losing work.
  bool get isBlank =>
      note.text.trim().isEmpty &&
      price.text.trim().isEmpty &&
      !hasCategory &&
      !hasSubCategory;

  void dispose() {
    note.dispose();
    price.dispose();
  }
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();

  /// Always holds at least one row. Editing an existing expense keeps exactly
  /// one, since a single record cannot become several.
  final List<_ExpenseRow> _rows = [];

  DateTime? date;
  bool isSnackbarShown = false;
  bool isFromEdit = false;

  NumberFormat formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_us',
    decimalDigits: 0,
  );

  @override
  void initState() {
    isFromEdit = widget._expenseCategory != null;
    date = DateTime.now();

    if (isFromEdit) {
      _rows.add(_ExpenseRow(
        note: widget._expenseCategory?.note ?? "",
        price: formatter.format(widget._expenseCategory?.price ?? 0),
        category: CategoryModel(
            categoryId: widget._expenseCategory?.categoryId ?? "",
            categoryName: widget._expenseCategory?.categoryName ?? "",
            categoryColor: widget._expenseCategory?.categoryColor ?? -1),
        subCategory: SubCategoryModel(
          subCategoryId: widget._expenseCategory?.subCategoryId ?? "",
          subCategoryName: widget._expenseCategory?.subCategoryName ?? "",
          subCategoryColor: widget._expenseCategory?.subCategoryColor ?? -1,
        ),
      ));
      date = widget._expenseCategory?.date.toDateGlobalFormat();
    } else if (widget.scannedReceipt != null) {
      final scan = widget.scannedReceipt!;
      // The scanner leaves the date null when the receipt had none printed, in
      // which case today is the sensible default.
      date = scan.date ?? DateTime.now();

      if (scan.items.isNotEmpty) {
        // Every legible line becomes its own expense row.
        for (final item in scan.items) {
          _rows.add(_ExpenseRow(
            note: item.note,
            price: formatter.format(item.price),
          ));
        }
      } else {
        // Only a total was readable, so fall back to one row for the whole
        // receipt, named after the merchant.
        _rows.add(_ExpenseRow(
          note: scan.note,
          price: scan.price == null ? "" : formatter.format(scan.price),
        ));
      }
    }

    if (_rows.isEmpty) _rows.add(_ExpenseRow());
    super.initState();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// A new row copies the previous row's type and category: consecutive items
  /// off one receipt usually share them, and it stays editable per row.
  void _addRow() => setState(() => _rows.add(_ExpenseRow(
        category: _rows.isEmpty ? null : _rows.last.category,
        subCategory: _rows.isEmpty ? null : _rows.last.subCategory,
      )));

  /// Copies a row's pick into every row that has none yet, so a scanned receipt
  /// needs one selection rather than one per line. Rows already set by hand are
  /// left alone.
  void _fillEmptyCategories(_ExpenseRow source) {
    for (final row in _rows) {
      if (!row.hasCategory) row.category = source.category;
      if (!row.hasSubCategory) row.subCategory = source.subCategory;
    }
  }

  void _removeRow(int index) {
    setState(() => _rows.removeAt(index).dispose());
  }

  /// Fills the form from the templates the user picked, one row each.
  ///
  /// Editing an existing expense overwrites the single row instead of adding
  /// more, since one record cannot become several.
  Future<void> _fillFromTemplates() async {
    final templates = await pickExpenseTemplates(context);
    if (templates == null || templates.isEmpty || !mounted) return;

    setState(() {
      if (isFromEdit) {
        _applyTemplate(_rows.first, templates.first);
        return;
      }

      // A row the user has already typed into is kept: the templates are added
      // after it rather than replacing what is there. Untouched blank rows are
      // dropped so picking one template does not leave an empty row behind.
      final blanks = _rows.where((row) => row.isBlank).toList();
      for (final row in blanks) {
        _rows.remove(row);
        row.dispose();
      }

      for (final template in templates) {
        final row = _ExpenseRow();
        _applyTemplate(row, template);
        _rows.add(row);
      }
    });
  }

  void _applyTemplate(_ExpenseRow row, ExpenseTemplateModel template) {
    row.note.text = template.note;
    // A template without a price leaves the field empty for the user to fill,
    // rather than writing a zero they would have to clear first.
    row.price.text = template.price > 0 ? formatter.format(template.price) : "";
    row.category = CategoryModel(
      categoryId: template.categoryId,
      categoryName: template.categoryName,
      categoryColor: template.categoryColor,
    );
    row.subCategory = SubCategoryModel(
      subCategoryId: template.subCategoryId,
      subCategoryName: template.subCategoryName,
      subCategoryColor: template.subCategoryColor,
    );
  }

  int get _rowsTotal =>
      _rows.fold(0, (sum, row) => sum + row.price.text.fromRupiah());

  /// What the dashboard shows in its "saved" snackbar. Naming a single row is
  /// more useful than a count; a batch is the other way round.
  String _savedSummary() =>
      _rows.length == 1 ? _rows.first.note.text : "${_rows.length} expenses";

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.locator<ExpenseBloc>()),
        // Hoisted to the form so the lookup lists are fetched once and shared by
        // every row's dropdowns. They also have to live above the "Add Type" and
        // "Add Category" buttons, which read them after their dialog closes.
        BlocProvider(
            create: (_) =>
                di.locator<CategoryBloc>()..add(const GetCategoryEvent())),
        BlocProvider(
            create: (_) => di.locator<SubcategoryBloc>()
              ..add(const GetSubcategoryEvent())),
      ],
      child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Form"),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              actions: [
                IconButton(
                  tooltip: "Manage templates",
                  icon: const Icon(Icons.bookmarks_outlined),
                  onPressed: () => Navigator.pushNamed(
                      context, ExpenseTemplatePage.routeName),
                ),
              ],
            ),
            body: SafeArea(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<ExpenseBloc, ExpenseState>(
                    listener: (context, state) {
                      if (state is ExpenseDataChanged) {
                        Navigator.pop(context, _savedSummary());
                        /* TODO, fcm call
                             context.read<FcmBloc>().add(
                                  PostFcmEvent(SendFcmRequest(
                                      to: "/topics/all",
                                      notification: FcmNotification(
                                        title:
                                            "${_savedSummary()} - Rp. ${_rowsTotal.toRupiah()}",
                                        body: "$date - ${categoryModel?.categoryName}",
                                      ))),
                                ); */
                      } else if (state is ExpenseError) {
                        context.show(state.message);
                      }
                    },
                  ),
                  BlocListener<FcmBloc, FcmState>(
                    listener: (context, state) {
                      if (state is FcmHasData) {
                        Navigator.pop(context, true);
                      } else if (state is FcmError) {
                        context.show(state.message);
                      }
                    },
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addDate(context),
                              fillFromTemplate(context),
                              addLookups(context),
                              itemsSection(context),
                            ],
                          ),
                          actionButton(context)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget actionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: OutlinedButton(
                onPressed: () {
                  submitForm(context);
                },
                child: Text(isFromEdit
                    ? "Update expense"
                    : _rows.length == 1
                        ? "Add expense"
                        : "Add ${_rows.length} expenses"),
              ),
            ),
          ),
          if (isFromEdit)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(width: 1.0, color: AppColors.red.primary),
                  ),
                  onPressed: () {
                    if (widget._expenseCategory?.id != null) {
                      context.read<ExpenseBloc>().add(DeleteExpenseEvent(
                          widget._expenseCategory?.id ?? ""));
                    }
                  },
                  child: Text(
                    "Delete",
                    style: TextStyle(color: AppColors.red.primary),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget addDate(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Expense date"),
          DatePickerWidget(callback: setDateState, initialDate: date),
        ],
      ),
    );
  }

  /// The editable expense lines. A receipt scan seeds one row per parsed item,
  /// and each row carries its own type and category so one receipt can span
  /// several. Only the date is shared.
  ///
  /// The lookup lists come from the form-level blocs, so all rows read them once
  /// rather than each dropdown fetching its own copy.
  Widget itemsSection(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final categories =
            categoryState is CategoryHasData ? categoryState.result : const [];

        return BlocBuilder<SubcategoryBloc, SubcategoryState>(
          builder: (context, subState) {
            final subCategories =
                subState is SubcategoryHasData ? subState.result : const [];

            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isFromEdit ? "Expense" : "Items (${_rows.length})",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _rows.length; i++)
                    expenseRow(context, i, categories.cast<CategoryModel>(),
                        subCategories.cast<SubCategoryModel>()),
                  if (!isFromEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: OutlinedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add),
                        label: const Text("Add item"),
                      ),
                    ),
                  if (_rows.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("Rp ${_rowsTotal.toRupiah()}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget expenseRow(
    BuildContext context,
    int index,
    List<CategoryModel> categories,
    List<SubCategoryModel> subCategories,
  ) {
    final row = _rows[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A hairline is all the separation rows need; a filled card competes
        // with the input fields for attention.
        if (index > 0)
          Divider(height: 32, color: Theme.of(context).dividerColor),
        Row(
          children: [
            Expanded(child: addNote(row)),
            // Removing the last row would leave nothing to submit.
            if (_rows.length > 1)
              IconButton(
                tooltip: "Remove item",
                onPressed: () => _removeRow(index),
                icon: Icon(Icons.close, color: AppColors.red.primary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          // Kept clear of the remove button's column so the price field lines up
          // with the name field above it.
          padding: EdgeInsets.only(right: _rows.length > 1 ? 48 : 0),
          child: addPrice(row),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: rowCategoryDdl(row, categories)),
            const SizedBox(width: 12),
            Expanded(child: rowSubCategoryDdl(row, subCategories)),
          ],
        ),
      ],
    );
  }

  Widget rowCategoryDdl(_ExpenseRow row, List<CategoryModel> categories) {
    // Matched by id rather than instance: the list is refetched, so the object
    // held by the row is not the same one the dropdown offers.
    final selected = categories.firstWhere(
      (item) => item.categoryId == row.category?.categoryId,
      orElse: () => CategoryModel(
          categoryId: "", categoryName: "", categoryColor: 0xff443a49),
    );

    return DropdownButton<CategoryModel>(
      value: selected.categoryId.isEmpty ? null : selected,
      hint: const Text("Type"),
      // Sharing the row with the category dropdown leaves half the width, so the
      // button fills its slot and long names ellipsize instead of overflowing.
      isExpanded: true,
      items: categories
          .map((item) => DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    SizedBox(
                      height: 15,
                      child: CircleAvatar(
                          backgroundColor: item.categoryColor.toColor()),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.categoryName,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          row.category = value;
          _fillEmptyCategories(row);
        });
      },
    );
  }

  Widget rowSubCategoryDdl(
      _ExpenseRow row, List<SubCategoryModel> subCategories) {
    final selected = subCategories.firstWhere(
      (item) => item.subCategoryId == row.subCategory?.subCategoryId,
      orElse: () => SubCategoryModel(
          subCategoryId: "", subCategoryName: "", subCategoryColor: 0xff443a49),
    );

    return DropdownButton<SubCategoryModel>(
      value: selected.subCategoryId.isEmpty ? null : selected,
      hint: const Text("Category"),
      isExpanded: true,
      items: subCategories
          .map((item) => DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    SizedBox(
                      height: 15,
                      child: CircleAvatar(
                          backgroundColor: item.subCategoryColor.toColor()),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.subCategoryName,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          row.subCategory = value;
          _fillEmptyCategories(row);
        });
      },
    );
  }

  Widget addNote(_ExpenseRow row) {
    return TextFormField(
      controller: row.note,
      decoration:
          textFormFieldStyle(context: context, hintText: "Expense Name.."),
      validator: (val) =>
          (val?.length ?? 0) <= 0 ? "Note cannot be empty" : null,
    );
  }

  Widget addPrice(_ExpenseRow row) {
    return TextFormField(
      controller: row.price,
      // The formatter rewrites the field as you type, which the web build
      // handles differently, so it stays mobile only as before.
      inputFormatters: kIsWeb ? null : [textInputFormatter()],
      keyboardType: TextInputType.number,
      decoration: textFormFieldStyle(context: context, hintText: "Price..")
          .copyWith(icon: const Text("Rp ")),
      validator: (val) => ((val?.fromRupiah() ?? 0) < 100)
          ? "Price should be grater than Rp 100"
          : null,
      // Keeps the running total in step with what is typed.
      onChanged: (_) => setState(() {}),
    );
  }

  /// Fills the rows from the templates the user saved, for the items entered
  /// day after day. Sits above the lookup buttons because it is the quicker
  /// path: it fills a whole row rather than only offering a dropdown value.
  Widget fillFromTemplate(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _fillFromTemplates,
          icon: const Icon(Icons.bookmark_border),
          label:
              Text(isFromEdit ? "Replace from template" : "Fill from template"),
        ),
      ),
    );
  }

  /// Creates new types and categories for the whole account. The per-row
  /// dropdowns only choose between what already exists, so this is where a
  /// missing one gets added.
  Widget addLookups(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                CategoryModel? result = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const AddCategoryDialog();
                  },
                );
                if (result == null || !context.mounted) return;

                // The dialog writes straight to Firestore, so the list is
                // refetched to pick the new entry up.
                context.read<CategoryBloc>().add(const GetCategoryEvent());
              },
              child: const Text("Add Type"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                SubCategoryModel? result = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const AddSubCategoryDialog();
                  },
                );
                if (result == null || !context.mounted) return;

                context
                    .read<SubcategoryBloc>()
                    .add(const GetSubcategoryEvent());
              },
              child: const Text(
                "Add Category",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void setDateState(DateTime date) {
    setState(() {
      this.date = date;
    });
  }

  bool submitForm(BuildContext context) {
    isSnackbarShown = false;

    // Every row needs its own type and category, so the offending row is named
    // rather than leaving the user to hunt for the blank dropdown.
    for (var i = 0; i < _rows.length; i++) {
      final label = _rows.length == 1 ? "" : " on item ${i + 1}";

      if (!_rows[i].hasCategory) {
        isSnackbarShown = true;
        context.showSb(
            SnackBar(content: Text("Type is empty$label")), isSnackbarShown);
        return false;
      }

      if (!_rows[i].hasSubCategory) {
        isSnackbarShown = true;
        context.showSb(SnackBar(content: Text("Category is empty$label")),
            isSnackbarShown);
        return false;
      }
    }

    if (date == null) {
      isSnackbarShown = true;
      context.showSb(
          const SnackBar(content: Text("Date is empty")), isSnackbarShown);
      return false;
    }

    if (_formKey.currentState!.validate()) {
      var insertedDate = date?.toDateString(DateFormatUtil.ddSlashMMSlashyyyy);
      var now = DateTime.now();
      var strYearSplit = (insertedDate ?? "").split("/");
      var insertedDayOfMonth = strYearSplit[0];
      var insertedMonth = strYearSplit[1];
      var insertedYear = strYearSplit[2];
      var timeStamp =
          "${now.hour.addZeroPref()}:${now.minute.addZeroPref()}:${now.second.addZeroPref()} ${now.day.addZeroPref()}/${now.month.addZeroPref()}/${now.year}";

      if (isFromEdit) {
        final row = _rows.first;
        context.read<ExpenseBloc>().add(UpdateExpenseEvent(UpdateExpenseRequest(
              id: widget._expenseCategory?.id ?? "",
              note: row.note.text,
              price: row.price.text.fromRupiah(),
              date: insertedDate ?? '',
              categoryId: row.category?.categoryId ?? "",
              subCategoryId: row.subCategory?.subCategoryId ?? "",
              year: insertedYear,
              month: insertedMonth,
              dayOfMonth: insertedDayOfMonth,
              timeStamp: timeStamp,
              status: StatusUtil.updated,
            )));
      } else {
        // One request per row, committed together. A single row goes down the
        // same path, so there is only one insert flow to reason about.
        final requests = _rows
            .map((row) => InsertExpenseRequest(
                  note: row.note.text,
                  price: row.price.text.fromRupiah(),
                  date: insertedDate ?? "",
                  categoryId: row.category?.categoryId ?? "",
                  subCategoryId: row.subCategory?.subCategoryId ?? "",
                  year: insertedYear,
                  month: insertedMonth,
                  dayOfMonth: insertedDayOfMonth,
                  timeStamp: timeStamp,
                  status: StatusUtil.inserted,
                ))
            .toList();

        context.read<ExpenseBloc>().add(InsertBatchExpenseEvent(requests));
      }

      return true;
    } else {
      return false;
    }
  }
}
