import 'package:core/domain/model/expense_template_model.dart';
import 'package:flutter/material.dart';
import 'package:group_expense_tracker/util/ext/int_util.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';
import 'package:group_expense_tracker/util/style/app_color_util.dart';

/// One saved template, as shown both on the manage page and in the picker.
///
/// [trailing] is what differs between the two: a delete button when managing,
/// a checkbox when picking.
class ExpenseTemplateTile extends StatelessWidget {
  final ExpenseTemplateModel template;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ExpenseTemplateTile({
    super.key,
    required this.template,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Material 3 cards default to their own tinted surface and ignore the
      // theme's cardColor, which left the tile darker than the page. This is
      // the same colour the form's input fields are filled with.
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(template.note,
            style: TextUtil(context)
                .plusJakarta(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(template.categoryName, template.categoryColor),
              _chip(template.subCategoryName, template.subCategoryColor),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // A template without a price only pre-picks the name and
              // category, which the list says outright so it does not read as
              // a free expense.
              template.price > 0
                  ? "Rp ${template.price.toRupiah()}"
                  : "No price",
              style: TextUtil(context).plusJakarta(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: template.price > 0 ? null : AppColors.grey.lightGray,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.toColor().withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
