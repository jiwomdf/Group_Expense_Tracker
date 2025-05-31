import 'package:core/data/network/request/send_fcm_request.dart';
import 'package:core/domain/model/failure.dart';
import 'package:core/util/resource/resource_util.dart';
import 'package:http/http.dart' as http;

class FcmRepository {
  static const serverKey = '';
  static const baseURL = 'https://fcm.googleapis.com/';
  final http.Client client;

  FcmRepository({required this.client});

  Future<ResourceUtil<bool>> sendFcm(SendFcmRequest request) async {
    try {
      final response = await client.post(Uri.parse('$baseURL/fcm/send'),
          body: request.toJson().toString(),
          headers: {
            'Content-type': 'application/json',
            'Authorization': 'key=$serverKey',
          });
      if (response.statusCode == 200) {
        return ResourceUtil.success(true);
      } else {
        return ResourceUtil.error(ServerFailure(response.body.toString()));
      }
    } catch (e) {
      return ResourceUtil.error(GeneralFailure(e.toString()));
    }
  }
}
