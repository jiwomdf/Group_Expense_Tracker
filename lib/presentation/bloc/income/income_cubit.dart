import 'package:bloc/bloc.dart';
import 'package:core/repository/app_setting_repository.dart';
import 'package:equatable/equatable.dart';

part 'income_state.dart';

class IncomeCubit extends Cubit<IncomeState> {
  final AppSettingRepository _appSettingRepository;

  IncomeCubit(this._appSettingRepository) : super(IncomeInitial());

  Future<void> updateIncome(int income) async {
    final success = await _appSettingRepository.updateIncome(income);
    emit(IncomeUpdated(isSuccess: success));
  }

  Future<void> getIncome() async {
    final income = await _appSettingRepository.getIncome() ?? 5000;
    emit(IncomeHasData(income: income));
  }
}
