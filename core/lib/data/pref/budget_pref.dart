import 'package:core/domain/model/failure.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The monthly budget is a personal target rather than shared group data, so it
/// stays on the device and is never written to firestore.
///
/// One amount applies to every month; `0` means the user has not set one.
class BudgetPref {
  final SharedPreferences prefs;

  static const String monthlyBudgetPref = 'monthly_budget_pref';

  BudgetPref({required this.prefs});

  Future<ResourceUtil<bool>> setMonthlyBudget(int amount) async {
    try {
      if (amount < 0) {
        return ResourceUtil.error(
            const GeneralFailure('budget cannot be negative'));
      }
      bool result = await prefs.setInt(monthlyBudgetPref, amount);
      return ResourceUtil.success(result);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<int>> getMonthlyBudget() async {
    try {
      int result = prefs.getInt(monthlyBudgetPref) ?? 0;
      return ResourceUtil.success(result);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }

  Future<ResourceUtil<bool>> clearMonthlyBudget() async {
    try {
      bool result = await prefs.remove(monthlyBudgetPref);
      return ResourceUtil.success(result);
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }
}
