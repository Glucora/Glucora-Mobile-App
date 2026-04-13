import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/admin_model.dart';

class AdminService {
  static final supabase = Supabase.instance.client;

  // ─── ALERT RULES ──────────────────────────────────────────────────────────────
  
  static Future<List<AdminAlertRule>> getAllAlertRules() async {
    try {
      final response = await supabase
          .from('alert_rules')
          .select('*')
          .order('severity', ascending: false);
      
      return (response as List)
          .map((rule) => AdminAlertRule.fromMap(rule))
          .toList();
    } catch (e) {
      debugPrint('Error fetching alert rules: $e');
      return [];
    }
  }

  static Future<bool> addAlertRule(AdminAlertRule rule) async {
    try {
      await supabase
          .from('alert_rules')
          .insert(rule.toMap());
      return true;
    } catch (e) {
      debugPrint('Error adding alert rule: $e');
      return false;
    }
  }

  static Future<bool> updateAlertRule(AdminAlertRule rule) async {
    try {
      await supabase
          .from('alert_rules')
          .update(rule.toMap())
          .eq('id', rule.id);
      return true;
    } catch (e) {
      debugPrint('Error updating alert rule: $e');
      return false;
    }
  }

  static Future<bool> deleteAlertRule(String ruleId) async {
    try {
      await supabase
          .from('alert_rules')
          .delete()
          .eq('id', ruleId);
      return true;
    } catch (e) {
      debugPrint('Error deleting alert rule: $e');
      return false;
    }
  }

  static Future<bool> toggleAlertRule(String ruleId, bool isEnabled) async {
    try {
      await supabase
          .from('alert_rules')
          .update({'is_enabled': isEnabled})
          .eq('id', ruleId);
      return true;
    } catch (e) {
      debugPrint('Error toggling alert rule: $e');
      return false;
    }
  }

  // ─── DEVICES ──────────────────────────────────────────────────────────────────
  
  static Future<List<AdminDevice>> getAllDevices() async {
    try {
      final devices = await supabase
          .from('devices')
          .select('*')
          .order('created_at', ascending: false);
      
      final List<AdminDevice> result = [];
      
      for (final device in devices as List) {
        String assignedUserName = 'Unassigned';
        
        if (device['patient_id'] != null) {
          final user = await supabase
              .from('users')
              .select('full_name')
              .eq('id', device['patient_id'])
              .maybeSingle();
          
          if (user != null) {
            assignedUserName = user['full_name'] as String? ?? 'Unknown';
          }
        }
        
        result.add(AdminDevice.fromMap(device, assignedUserName: assignedUserName));
      }
      
      return result;
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      return [];
    }
  }

  static Future<bool> assignDevice(String deviceId, String patientId) async {
    try {
      await supabase
          .from('devices')
          .update({'patient_id': patientId, 'is_active': true})
          .eq('id', deviceId);
      return true;
    } catch (e) {
      debugPrint('Error assigning device: $e');
      return false;
    }
  }

  static Future<bool> unassignDevice(String deviceId) async {
    try {
      await supabase
          .from('devices')
          .update({'patient_id': null, 'is_active': false})
          .eq('id', deviceId);
      return true;
    } catch (e) {
      debugPrint('Error unassigning device: $e');
      return false;
    }
  }

  static Future<bool> addDevice(AdminDevice device) async {
    try {
      await supabase
          .from('devices')
          .insert(device.toMap());
      return true;
    } catch (e) {
      debugPrint('Error adding device: $e');
      return false;
    }
  }

  static Future<bool> updateDevice(AdminDevice device) async {
    try {
      await supabase
          .from('devices')
          .update(device.toMap())
          .eq('id', device.id);
      return true;
    } catch (e) {
      debugPrint('Error updating device: $e');
      return false;
    }
  }

  static Future<bool> deleteDevice(String deviceId) async {
    try {
      await supabase
          .from('devices')
          .delete()
          .eq('id', deviceId);
      return true;
    } catch (e) {
      debugPrint('Error deleting device: $e');
      return false;
    }
  }

  // ─── USERS ────────────────────────────────────────────────────────────────────
  
  static Future<List<AdminUser>> getAllUsers() async {
    try {
      final response = await supabase
          .from('users')
          .select('*')
          .order('created_at', ascending: false);
      
      return (response as List).map((user) => AdminUser.fromMap(user)).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  static Future<bool> updateUser(AdminUser user) async {
    try {
      await supabase
          .from('users')
          .update(user.toMap())
          .eq('id', user.id);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await supabase
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error toggling user status: $e');
      return false;
    }
  }

  // ─── DOCTOR-PATIENT ASSIGNMENTS ──────────────────────────────────────────────
  
  static Future<List<DoctorPatientAssignment>> getAllAssignments() async {
    try {
      final connections = await supabase
          .from('doctor_patient_connections')
          .select('doctor_id, patient_id')
          .eq('status', 'accepted');
      
      final List<DoctorPatientAssignment> assignments = [];
      
      for (final conn in connections as List) {
        final doctorId = conn['doctor_id'] as String;
        final patientId = conn['patient_id'] as String;
        
        final [doctorData, patientData] = await Future.wait([
          supabase.from('users').select('full_name').eq('id', doctorId).single(),
          supabase.from('users').select('full_name').eq('id', patientId).single(),
        ]);
        
        assignments.add(DoctorPatientAssignment(
          doctorId: doctorId,
          doctorName: doctorData['full_name'] as String? ?? 'Unknown Doctor',
          patientId: patientId,
          patientName: patientData['full_name'] as String? ?? 'Unknown Patient',
        ));
      }
      
      return assignments;
    } catch (e) {
      debugPrint('Error fetching assignments: $e');
      return [];
    }
  }

  static Future<bool> assignDoctorToPatient(String doctorId, String patientId) async {
    try {
      // Check if assignment already exists
      final existing = await supabase
          .from('doctor_patient_connections')
          .select()
          .eq('doctor_id', doctorId)
          .eq('patient_id', patientId)
          .maybeSingle();
      
      if (existing != null) {
        debugPrint('Assignment already exists');
        return false;
      }
      
      await supabase
          .from('doctor_patient_connections')
          .insert({
            'doctor_id': doctorId,
            'patient_id': patientId,
            'status': 'accepted',
          });
      return true;
    } catch (e) {
      debugPrint('Error assigning doctor to patient: $e');
      return false;
    }
  }

  static Future<bool> removeAssignment(String doctorId, String patientId) async {
    try {
      await supabase
          .from('doctor_patient_connections')
          .delete()
          .eq('doctor_id', doctorId)
          .eq('patient_id', patientId);
      return true;
    } catch (e) {
      debugPrint('Error removing assignment: $e');
      return false;
    }
  }

  // ─── STATISTICS ───────────────────────────────────────────────────────────────
  
  static Future<Map<String, int>> getStats() async {
    try {
      final usersResponse = await supabase.from('users').select('id');
      final devicesResponse = await supabase.from('devices').select('id').eq('is_active', true);
      final rulesResponse = await supabase.from('alert_rules').select('id');
      
      return {
        'totalUsers': (usersResponse as List).length,
        'activeDevices': (devicesResponse as List).length,
        'alertRules': (rulesResponse as List).length,
      };
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return {'totalUsers': 0, 'activeDevices': 0, 'alertRules': 0};
    }
  }
}