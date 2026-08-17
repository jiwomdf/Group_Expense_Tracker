import 'dart:convert';

import 'package:core/domain/model/expense_template_model.dart';
import 'package:core/domain/model/failure.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's expense templates on the device.
///
/// Like the monthly budget these are a personal convenience rather than shared
/// group data, so they never go to firestore. The whole list lives under one
/// key as a json array, which keeps saving and reordering a single write.
class ExpenseTemplatePref {
  final SharedPreferences prefs;

  static const String expenseTemplatePref = 'expense_template_pref';

  ExpenseTemplatePref({required this.prefs});

  Future<ResourceUtil<List<ExpenseTemplateModel>>> getTemplates() async {
    try {
      return ResourceUtil.success(_read());
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  /// Inserts the template, or replaces the one with the same id. One method for
  /// both so the page does not have to know whether it is adding or editing.
  Future<ResourceUtil<List<ExpenseTemplateModel>>> saveTemplate(
      ExpenseTemplateModel template) async {
    try {
      if (template.id.isEmpty) {
        return ResourceUtil.error(
            const GeneralFailure('template id cannot be empty'));
      }
      if (template.note.trim().isEmpty) {
        return ResourceUtil.error(
            const GeneralFailure('template name cannot be empty'));
      }

      final templates = _read();
      final index = templates.indexWhere((item) => item.id == template.id);

      if (index >= 0) {
        templates[index] = template;
      } else {
        templates.add(template);
      }

      return await _write(templates);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<List<ExpenseTemplateModel>>> deleteTemplate(
      String id) async {
    try {
      final templates = _read()..removeWhere((item) => item.id == id);
      return await _write(templates);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<List<ExpenseTemplateModel>>> clearTemplates() async {
    try {
      await prefs.remove(expenseTemplatePref);
      return ResourceUtil.success(const []);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  List<ExpenseTemplateModel> _read() {
    final stored = prefs.getString(expenseTemplatePref) ?? '';
    if (stored.isEmpty) return [];

    final decoded = jsonDecode(stored);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseTemplateModel.fromMap)
        .toList();
  }

  /// Returns the saved list rather than a bare bool, so the caller can render
  /// the result of the write without reading the store again.
  Future<ResourceUtil<List<ExpenseTemplateModel>>> _write(
      List<ExpenseTemplateModel> templates) async {
    final encoded = jsonEncode(templates.map((item) => item.toJson()).toList());
    await prefs.setString(expenseTemplatePref, encoded);
    return ResourceUtil.success(templates);
  }
}
