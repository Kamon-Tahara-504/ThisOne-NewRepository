/// リポジトリの基底例外クラス
class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;

  const RepositoryException(this.message, [this.originalError]);

  @override
  String toString() => 'RepositoryException: $message';
}

/// 認証エラー
class AuthRepositoryException extends RepositoryException {
  const AuthRepositoryException(super.message, [super.originalError]);
}

/// タスクエラー
class TaskRepositoryException extends RepositoryException {
  const TaskRepositoryException(super.message, [super.originalError]);
}

/// メモエラー
class MemoRepositoryException extends RepositoryException {
  const MemoRepositoryException(super.message, [super.originalError]);
}

/// スケジュールエラー
class ScheduleRepositoryException extends RepositoryException {
  const ScheduleRepositoryException(super.message, [super.originalError]);
}

/// 認証が必要なエラー
class UnauthorizedException extends RepositoryException {
  const UnauthorizedException() : super('認証が必要です');
}
