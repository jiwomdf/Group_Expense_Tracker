import 'package:core/data/network/error_handler.dart';
import 'package:core/domain/model/failure.dart';

class HttpFailure extends Failure {
  final int code;
  final DataSource dataSource;

  const HttpFailure(this.code, String message, this.dataSource)
      : super(message);
}
