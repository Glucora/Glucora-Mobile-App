import '../../core/models/admin_model.dart';
import 'base_repository.dart';

class AlertRepository extends BaseRepository {
  const AlertRepository(super.db);

  Future<List<AdminAlert>> getAll() async {
    final response = await db
        .from('alerts')
        .select('*')
        .order('triggered_at', ascending: false);
    return (response as List).map((a) => AdminAlert.fromMap(a)).toList();
  }

  Future<void> delete(int id) async {
    await db.from('alerts').delete().eq('id', id);
  }

  Future<List<AdminAlertRule>> getAllRules() async {
    final response = await db
        .from('alert_rules')
        .select('*')
        .order('severity', ascending: false);
    return (response as List).map((r) => AdminAlertRule.fromMap(r)).toList();
  }

  Future<void> addRule(AdminAlertRule rule) async {
    await db.from('alert_rules').insert(rule.toMap());
  }

  Future<void> updateRule(AdminAlertRule rule) async {
    await db.from('alert_rules').update(rule.toMap()).eq('id', rule.id);
  }

  Future<void> deleteRule(String ruleId) async {
    await db.from('alert_rules').delete().eq('id', ruleId);
  }

  Future<void> toggleRule(String ruleId, bool isEnabled) async {
    await db
        .from('alert_rules')
        .update({'is_enabled': isEnabled})
        .eq('id', ruleId);
  }
}