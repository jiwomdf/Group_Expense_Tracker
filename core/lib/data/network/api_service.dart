import 'package:core/data/network/util/netowrk_util.dart';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  //final NetworkInfo _networkInfo;

  ApiService(
    this._dio,
    /*this._networkInfo*/
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        // onError: _onError,
      ),
    );
  }

  _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    return handler.next(options);

    /* if (await _networkInfo.isConnected) {
      // String? token = _appPref.getToken();
      // options.headers['Authorization'] = 'Bearer $token';
      return handler.next(options);
    } else {
      return handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: ResponseCode.noInternetConnection,
            statusMessage: ResponseMessage.noInternetConnection,
          ),
          error: ResponseMessage.noInternetConnection,
        ),
      );
    } */
  }

  /* _onError(DioException e, ErrorInterceptorHandler handler) async {
    if (e.response?.statusCode == 423 && _appPref.isUserLogged()) {
      _logout();
      handler.reject(e);
    } else if (e.response?.statusCode == 401 && _appPref.isUserLogged()) {
      _refreshToken(e, handler);
    } else {
      handler.next(e);
    }
  }*/

  Future<Response> get(
      {required String endPoint, dynamic data, dynamic params}) async {
    var response = await _dio.get('${NetowrkUtil.baseUrl}$endPoint',
        data: data, queryParameters: params);
    return response;
  }

  Future<Response> post(
      {required String endPoint, dynamic data, dynamic params}) async {
    var response = await _dio.post('${NetowrkUtil.baseUrl}$endPoint',
        data: data, queryParameters: params);
    return response;
  }

  Future<Response> put({required String endPoint}) async {
    var response = await _dio.put('${NetowrkUtil.baseUrl}$endPoint');
    return response;
  }

  Future<Response> delete({required String endPoint}) async {
    var response = await _dio.delete('${NetowrkUtil.baseUrl}$endPoint');
    return response;
  }
}
