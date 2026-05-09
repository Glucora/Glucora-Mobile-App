import 'package:supabase_flutter/supabase_flutter.dart';

class RepositoryException implements Exception {
  final String message;
  final String? code;

  const RepositoryException(this.message, {this.code});

  @override
  String toString() => 'RepositoryException($code): $message';
}

abstract class BaseRepository {
  final SupabaseClient db;
  const BaseRepository(this.db);

  // For operations that return a value
  Future<T> safeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, code: e.code);
    } catch (e) {
      throw RepositoryException('Unexpected error: $e');
    }
  }

  // For void operations (update, delete, etc.)
  Future<void> safeVoidQuery(Future<void> Function() query) async {
    try {
      await query();
    } on PostgrestException catch (e) {
      throw RepositoryException(e.message, code: e.code);
    } catch (e) {
      throw RepositoryException('Unexpected error: $e');
    }
  }
}