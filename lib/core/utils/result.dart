/// Result type for handling success and error states
/// 
/// Similar to Rust's Result type, this helps avoid throwing exceptions
/// for expected error cases.
sealed class Result<T> {
  const Result();
}

/// Success result containing data
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// Error result containing error message
final class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;
}

/// Extension methods for Result
extension ResultExtension<T> on Result<T> {
  /// Returns true if result is success
  bool get isSuccess => this is Success<T>;

  /// Returns true if result is failure
  bool get isFailure => this is Failure<T>;

  /// Gets data if success, null otherwise
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// Gets error message if failure, null otherwise
  String? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final message) => message,
      };

  /// Maps the data type
  Result<R> map<R>(R Function(T) mapper) => switch (this) {
        Success<T>(:final data) => Success(mapper(data)),
        Failure<T>(:final message) => Failure(message),
      };

  /// Maps the error message
  Result<T> mapError(String Function(String) mapper) => switch (this) {
        Success<T>() => this,
        Failure<T>(:final message) => Failure(mapper(message)),
      };
}


