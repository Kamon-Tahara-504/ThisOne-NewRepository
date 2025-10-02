import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../repositories/auth/auth_repository.dart';
import '../repositories/auth/auth_repository_impl.dart';
import '../repositories/task/task_repository.dart';
import '../repositories/task/task_repository_impl.dart';
import '../repositories/memo/memo_repository.dart';
import '../repositories/memo/memo_repository_impl.dart';
import '../repositories/schedule/schedule_repository.dart';
import '../repositories/schedule/schedule_repository_impl.dart';

// SupabaseServiceのProvider

/// SupabaseServiceのシングルトンProvider
/// 全てのRepositoryで共有される
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Repository Providers

/// 認証Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthRepositoryImpl(supabaseService);
});

/// タスクRepository Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return TaskRepositoryImpl(supabaseService);
});

/// メモRepository Provider
final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MemoRepositoryImpl(supabaseService);
});

/// スケジュールRepository Provider
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ScheduleRepositoryImpl(supabaseService);
});
