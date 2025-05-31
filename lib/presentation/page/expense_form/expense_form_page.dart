import 'package:core/data/network/request/insert_expense_request.dart';
import 'package:core/data/network/request/update_expense_request.dart';
import 'package:core/domain/model/category_model.dart';
import 'package:core/domain/model/expense_category_model.dart';
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
import 'package:group_expense_tracker/presentation/widget/category_ddl_widget.dart';
import 'package:group_expense_tracker/presentation/widget/subcategory_ddl_widget.dart';
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

  const ExpenseFormPage(
      {super.key, required ExpenseCategoryModel? expenseCategory})
      : _expenseCategory = expenseCategory;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  String note = "";
  String price = "";
  DateTime? date;
  CategoryModel? categoryModel;
  SubCategoryModel? subCategoryModel;
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
      note = widget._expenseCategory?.note ?? "";
      price = formatter.format(widget._expenseCategory?.price ?? 0);
      categoryModel = CategoryModel(
          categoryId: widget._expenseCategory?.categoryId ?? "",
          categoryName: widget._expenseCategory?.categoryName ?? "",
          categoryColor: widget._expenseCategory?.categoryColor ?? -1);
      subCategoryModel = SubCategoryModel(
        subCategoryId: widget._expenseCategory?.subCategoryId ?? "",
        subCategoryName: widget._expenseCategory?.subCategoryName ?? "",
        subCategoryColor: widget._expenseCategory?.subCategoryColor ?? -1,
      );
      date = widget._expenseCategory?.date.toDateGlobalFormat();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.locator<ExpenseBloc>()),
      ],
      child: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Form"),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            body: SafeArea(
              child: MultiBlocListener(
                listeners: [
                  BlocListener<ExpenseBloc, ExpenseState>(
                    listener: (context, state) {
                      if (state is ExpenseDataChanged) {
                        Navigator.pop(context, note);
                        /* TODO, fcm call
                             context.read<FcmBloc>().add(
                                  PostFcmEvent(SendFcmRequest(
                                      to: "/topics/all",
                                      notification: FcmNotification(
                                        title:
                                            "$note - Rp. ${price.fromRupiah().toRupiah()}",
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
                              addNote(),
                              addDate(context),
                              addType(context),
                              addCategory(context),
                              addPrice(),
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
                child: Text(isFromEdit ? "Update expense" : "Add expense"),
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

  Widget addNote() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: widget._expenseCategory?.note ?? "",
        decoration:
            textFormFieldStyle(context: context, hintText: "Expense Name.."),
        validator: (val) =>
            (val?.length ?? 0) <= 0 ? "Note cannot be empty" : null,
        onChanged: (val) {
          setState(() => note = val);
        },
      ),
    );
  }

  Widget addPrice() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Builder(builder: (context) {
        if (kIsWeb) {
          return TextFormField(
            initialValue: widget._expenseCategory?.price.toRupiah() ?? "",
            keyboardType: TextInputType.number,
            decoration:
                textFormFieldStyle(context: context, hintText: "Price..")
                    .copyWith(icon: const Text("Rp ")),
            validator: (val) => ((val?.fromRupiah() ?? 0) < 100)
                ? "Price should be grater than Rp 100"
                : null,
            onChanged: (val) {
              setState(() {
                price = val.toString().replaceAll(",", "");
              });
            },
          );
        } else {
          return TextFormField(
            initialValue: widget._expenseCategory?.price.toRupiah() ?? "",
            inputFormatters: [textInputFormatter()],
            keyboardType: TextInputType.number,
            decoration:
                textFormFieldStyle(context: context, hintText: "Price..")
                    .copyWith(icon: const Text("Rp ")),
            validator: (val) => ((val?.fromRupiah() ?? 0) < 100)
                ? "Price should be grater than Rp 100"
                : null,
            onChanged: (val) {
              setState(() {
                int priceNum = val.fromRupiah();
                price = formatter.format(priceNum);
              });
            },
          );
        }
      }),
    );
  }

  Widget addType(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) {
            return CategoryDdlWidget(
              initialData: categoryModel,
              selectedCategory: (value) {
                setState(() {
                  categoryModel = value;
                });
              },
            );
          }),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: OutlinedButton(
                  onPressed: () async {
                    CategoryModel? result = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const AddCategoryDialog();
                      },
                    );
                    setState(() {
                      categoryModel = result;
                    });
                    await Future.delayed(const Duration(seconds: 1));
                    if (context.mounted) {
                      context
                          .read<CategoryBloc>()
                          .add(const GetCategoryEvent());
                    }
                  },
                  child: const Text("Add Type")),
            ),
          )
        ],
      ),
    );
  }

  Widget addCategory(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(builder: (context) {
                  return SubCategoryDdlWidget(
                    initialData: subCategoryModel,
                    selectedCategory: (value) {
                      setState(() {
                        subCategoryModel = value;
                      });
                    },
                  );
                }),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: OutlinedButton(
                        onPressed: () async {
                          SubCategoryModel? result = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const AddSubCategoryDialog();
                            },
                          );
                          setState(() {
                            subCategoryModel = result;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            context
                                .read<SubcategoryBloc>()
                                .add(const GetSubcategoryEvent());
                          }
                        },
                        child: const Text(
                          "Add Category",
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                )
              ],
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

    if (categoryModel?.categoryId.isEmpty == true ||
        categoryModel?.categoryName.isEmpty == true ||
        categoryModel?.categoryColor == null) {
      isSnackbarShown = true;
      context.showSb(
          const SnackBar(content: Text("Type is empty")), isSnackbarShown);
      return false;
    }

    if (subCategoryModel?.subCategoryId.isEmpty == true ||
        subCategoryModel?.subCategoryName == null ||
        subCategoryModel?.subCategoryColor == null) {
      isSnackbarShown = true;
      context.showSb(
          const SnackBar(content: Text("Category is empty")), isSnackbarShown);
      return false;
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
        context.read<ExpenseBloc>().add(UpdateExpenseEvent(UpdateExpenseRequest(
              id: widget._expenseCategory?.id ?? "",
              note: note,
              price: price.fromRupiah(),
              date: insertedDate ?? '',
              categoryId: categoryModel?.categoryId ?? "",
              subCategoryId: subCategoryModel?.subCategoryId ?? "",
              year: insertedYear,
              month: insertedMonth,
              dayOfMonth: insertedDayOfMonth,
              timeStamp: timeStamp,
              status: StatusUtil.updated,
            )));
      } else {
        context.read<ExpenseBloc>().add(InsertExpenseEvent(InsertExpenseRequest(
              note: note,
              price: price.fromRupiah(),
              date: insertedDate ?? "",
              categoryId: categoryModel?.categoryId ?? "",
              subCategoryId: subCategoryModel?.subCategoryId ?? "",
              year: insertedYear,
              month: insertedMonth,
              dayOfMonth: insertedDayOfMonth,
              timeStamp: timeStamp,
              status: StatusUtil.inserted,
            )));
      }

      return true;
    } else {
      return false;
    }
  }
}
