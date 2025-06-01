import 'package:bloc/bloc.dart';
import 'package:core/repository/auth_repository.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:equatable/equatable.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc(this._authRepository) : super(RegisterInitial()) {
    on<GetRegisterEvent>((event, emit) async {
      emit(RegisterLoading());
      final result =
          await _authRepository.register(event.email, event.password);

      switch (result.status) {
        case Status.success:
          emit(RegisterHasData(result.data ?? false));
          break;
        case Status.error:
          emit(RegisterError(result.failure?.message ?? ""));
          break;
      }
    });
  }
}
