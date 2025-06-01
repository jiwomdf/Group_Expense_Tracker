import 'package:bloc/bloc.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:core/repository/auth_repository.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc(this._authRepository) : super(LoginInitial()) {
    on<GetLoginEvent>((event, emit) async {
      emit(LoginLoading());
      final result = await _authRepository.login(event.email, event.password);

      switch (result.status) {
        case Status.success:
          if (result.data != null) {
            final nonNullData = result.data as UserDataModel;
            emit(LoginHasData(nonNullData));
          } else {
            emit(const LoginError("Something went wrong"));
          }
          break;
        case Status.error:
          emit(LoginError(result.failure?.message ?? ""));
          break;
      }
    });
  }
}
