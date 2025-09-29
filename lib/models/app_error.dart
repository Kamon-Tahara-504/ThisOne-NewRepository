/// アプリケーション全体で使用するエラーモデル
class AppError {
  final String message;
  final String? code;
  final ErrorType type;
  final DateTime timestamp;
  final String? stackTrace;

  const AppError({
    required this.message,
    this.code,
    required this.type,
    required this.timestamp,
    this.stackTrace,
  });

  factory AppError.network(String message, {String? code, String? stackTrace}) {
    return AppError(
      message: message,
      code: code,
      type: ErrorType.network,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
  }

  factory AppError.authentication(String message, {String? code, String? stackTrace}) {
    return AppError(
      message: message,
      code: code,
      type: ErrorType.authentication,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
  }

  factory AppError.validation(String message, {String? code, String? stackTrace}) {
    return AppError(
      message: message,
      code: code,
      type: ErrorType.validation,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
  }

  factory AppError.database(String message, {String? code, String? stackTrace}) {
    return AppError(
      message: message,
      code: code,
      type: ErrorType.database,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
  }

  factory AppError.unknown(String message, {String? code, String? stackTrace}) {
    return AppError(
      message: message,
      code: code,
      type: ErrorType.unknown,
      timestamp: DateTime.now(),
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'AppError(type: ${type.name}, message: $message, code: $code)';
  }
}

/// エラータイプの定義
enum ErrorType {
  network,
  authentication,
  validation,
  database,
  unknown,
}

/// エラーレベルの定義
enum ErrorLevel {
  info,
  warning,
  error,
  critical,
}

/// エラーレベルを取得するヘルパー関数
ErrorLevel getErrorLevel(AppError error) {
  switch (error.type) {
    case ErrorType.network:
      return ErrorLevel.warning;
    case ErrorType.authentication:
      return ErrorLevel.error;
    case ErrorType.validation:
      return ErrorLevel.info;
    case ErrorType.database:
      return ErrorLevel.error;
    case ErrorType.unknown:
      return ErrorLevel.critical;
  }
}
