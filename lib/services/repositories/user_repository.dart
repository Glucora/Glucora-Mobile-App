import '../../core/models/admin_model.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  const UserRepository(super.db);

  Future<List<AdminUser>> getAll() async {
    final response = await db
        .from('users')
        .select('*')
        .order('created_at', ascending: false);
    return (response as List).map((u) => AdminUser.fromMap(u)).toList();
  }

  Future<void> update(AdminUser user) async {
    await db.from('users').update(user.toMap()).eq('id', user.id);
  }

  Future<void> toggleStatus(String userId, bool isActive) async {
    await db
        .from('users')
        .update({'is_active': isActive})
        .eq('id', userId);
  }

  Future<int> getCount() async {
    final response = await db.from('users').select('id');
    return (response as List).length;
  }
}