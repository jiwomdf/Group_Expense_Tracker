import 'package:core/domain/model/failure.dart';

enum Status { success, error }

class ResourceUtil<T> {
  final Status status;
  final T? data;
  final Failure? failure;

  ResourceUtil._(this.status, this.data, this.failure);

  factory ResourceUtil.success(T? data) =>
      ResourceUtil._(Status.success, data, null);
  factory ResourceUtil.error(Failure? failure, [T? data]) =>
      ResourceUtil._(Status.error, data, failure);
}
