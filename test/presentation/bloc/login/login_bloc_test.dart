import 'package:bloc_test/bloc_test.dart';
import 'package:core/domain/model/user_model.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/login/login_bloc.dart';
import 'package:mockito/mockito.dart';

import '../../../helper/test_helper.mocks.dart';

void main() {
  late LoginBloc loginBloc;
  late MockAuthRepository mockAuthRepository;
  late UserDataModel userDataModel;
  const email = "email@gmail.com";
  const password = "password";

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginBloc = LoginBloc(mockAuthRepository);
    userDataModel = UserDataModel(uid: "uid", name: "name", email: "email");
  });

  blocTest<LoginBloc, LoginState>(
    'Should emit [GetLoginEvent] when data is inserted successfully',
    build: () {
      when(mockAuthRepository.login(email, password))
          .thenAnswer((_) async => ResourceUtil.success(userDataModel));
      return loginBloc;
    },
    act: (bloc) => bloc.add(const GetLoginEvent(email, password)),
    expect: () => [
      LoginLoading(),
      LoginHasData(userDataModel),
    ],
    verify: (bloc) {
      verify(mockAuthRepository.login(email, password));
      return const GetLoginEvent(email, password).props;
    },
  );
}
