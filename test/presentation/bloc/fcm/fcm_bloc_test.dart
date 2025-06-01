import 'package:bloc_test/bloc_test.dart';
import 'package:core/data/network/request/send_fcm_request.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_expense_tracker/presentation/bloc/fcm/fcm_bloc.dart';
import 'package:mockito/mockito.dart';

import '../../../helper/test_helper.mocks.dart';

void main() {
  late FcmBloc fcmBloc;
  late SendFcmRequest sendFcmRequest;
  late MockFcmRepository mockFcmRepository;

  setUp(() {
    mockFcmRepository = MockFcmRepository();
    fcmBloc = FcmBloc(mockFcmRepository);
    sendFcmRequest = SendFcmRequest(
        to: "token",
        notification: FcmNotification(
          title: "title",
          body: "body",
        ));
  });

  blocTest<FcmBloc, FcmState>(
    'Should emit [ExpenseDataChanged] when data is inserted successfully',
    build: () {
      when(mockFcmRepository.sendFcm(sendFcmRequest))
          .thenAnswer((_) async => ResourceUtil.success(true));
      return fcmBloc;
    },
    act: (bloc) => bloc.add(PostFcmEvent(sendFcmRequest)),
    expect: () => [
      FcmLoading(),
      const FcmHasData(true),
    ],
    verify: (bloc) {
      verify(mockFcmRepository.sendFcm(sendFcmRequest));
      return PostFcmEvent(sendFcmRequest).props;
    },
  );
}
