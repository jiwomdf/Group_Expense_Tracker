import 'package:bloc_test/bloc_test.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/register/register_bloc.dart';
import 'package:mockito/mockito.dart';

import '../../../helper/test_helper.mocks.dart';

void main() {
  late RegisterBloc registerBloc;
  late MockAuthRepository mockAuthRepository;
  const email = "email@gmail.com";
  const password = "password";

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    registerBloc = RegisterBloc(mockAuthRepository);
  });

  blocTest<RegisterBloc, RegisterState>(
    'Should emit [GetLoginEvent] when data is inserted successfully',
    build: () {
      when(mockAuthRepository.register(email, password))
          .thenAnswer((_) async => ResourceUtil.success(true));
      return registerBloc;
    },
    act: (bloc) => bloc.add(const GetRegisterEvent(email, password)),
    expect: () => [
      RegisterLoading(),
      const RegisterHasData(true),
    ],
    verify: (bloc) {
      verify(mockAuthRepository.register(email, password));
      return const GetRegisterEvent(email, password).props;
    },
  );
}
