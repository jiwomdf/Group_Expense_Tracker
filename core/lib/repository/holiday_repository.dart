import 'package:core/data/network/api_service.dart';
import 'package:core/data/network/error_handler.dart';
import 'package:core/data/network/response/holiday_response.dart';
import 'package:core/util/resource/resource_util.dart';

class HolidayRepository {
  final ApiService _apiService;

  HolidayRepository(this._apiService);

  Future<ResourceUtil<List<HolidayResponse>>> getHolidays(
      int year, String countryCode) async {
    try {
      final response =
          await _apiService.get(endPoint: "PublicHolidays/$year/$countryCode");
      final data = HolidayResponse.toListMap(response.data);
      return ResourceUtil.success(data);
    } catch (error) {
      return ResourceUtil.error(ErrorHandler.handle(error).failure);
    }
  }
}
