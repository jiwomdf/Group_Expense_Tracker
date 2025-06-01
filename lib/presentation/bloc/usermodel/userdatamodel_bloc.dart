import 'package:bloc/bloc.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:core/repository/auth_repository.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'userdatamodel_event.dart';
part 'userdatamodel_state.dart';

class UserDataModelBloc extends Bloc<UserDataModelEvent, UserDataModelState> {
  final AuthRepository _authRepository;

  UserDataModelBloc(this._authRepository) : super(UserDataModelLoading()) {
    on<GetUserDataModelEvent>((event, emit) async {
      emit(UserDataModelLoading());
      final result = await _authRepository.getUserDataModel();

      switch (result.status) {
        case Status.success:
          if (result.data != null) {
            final nonNullValue = result.data as UserDataModel;
            emit(UserDataModelHasData(nonNullValue));
          } else {
            emit(UserDataModelError(result.failure?.message ?? ""));
          }
          break;
        case Status.error:
          emit(UserDataModelError(result.failure?.message ?? ""));
          break;
      }
    });
  }
}
