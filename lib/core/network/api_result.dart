sealed class ApiResult<T> {
  const ApiResult();
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

final class ApiError<T> extends ApiResult<T> {
  const ApiError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;
}
