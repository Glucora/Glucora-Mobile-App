import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/admin_model.dart';
import '../services/repositories/alert_repository.dart';
import '../services/repositories/assignment_repository.dart';
import '../services/repositories/device_repository.dart';
import '../services/repositories/user_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AlertRepository _alertRepo;
  final DeviceRepository _deviceRepo;
  final UserRepository _userRepo;
  final AssignmentRepository _assignmentRepo;

  AdminProvider()
      : _alertRepo = AlertRepository(Supabase.instance.client),
        _deviceRepo = DeviceRepository(Supabase.instance.client),
        _userRepo = UserRepository(Supabase.instance.client),
        _assignmentRepo = AssignmentRepository(Supabase.instance.client);

  // ─── STATE ────────────────────────────────────────────────────────────────

  List<AdminAlert> alerts = [];
  List<AdminAlertRule> alertRules = [];
  List<AdminDevice> devices = [];
  List<AdminUser> users = [];
  List<DoctorPatientAssignment> assignments = [];

  bool isLoading = false;
  String? errorMessage;

  int totalUsers = 0;
  int activeDevices = 0;
  int inactiveDevices = 0;
  int totalDevices = 0;
  int totalAlertRules = 0;

  // ─── ALERTS ───────────────────────────────────────────────────────────────

  Future<void> loadAlerts() async {
    _setLoading(true);
    try {
      alerts = await _alertRepo.getAll();
    } catch (e) {
      _setError('Failed to load alerts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAlert(int id) async {
    try {
      await _alertRepo.delete(id);
      alerts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete alert: $e');
    }
  }

  // ─── ALERT RULES ──────────────────────────────────────────────────────────

  Future<void> loadAlertRules() async {
    _setLoading(true);
    try {
      alertRules = await _alertRepo.getAllRules();
    } catch (e) {
      _setError('Failed to load alert rules: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAlertRule(AdminAlertRule rule) async {
    try {
      await _alertRepo.addRule(rule);
      await loadAlertRules();
    } catch (e) {
      _setError('Failed to add alert rule: $e');
    }
  }

  Future<void> updateAlertRule(AdminAlertRule rule) async {
    try {
      await _alertRepo.updateRule(rule);
      final index = alertRules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        alertRules[index] = rule;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update alert rule: $e');
    }
  }

  Future<void> deleteAlertRule(String ruleId) async {
    try {
      await _alertRepo.deleteRule(ruleId);
      alertRules.removeWhere((r) => r.id == ruleId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete alert rule: $e');
    }
  }

  Future<void> toggleAlertRule(String ruleId, bool isEnabled) async {
    try {
      await _alertRepo.toggleRule(ruleId, isEnabled);
      final index = alertRules.indexWhere((r) => r.id == ruleId);
      if (index != -1) {
        alertRules[index].isEnabled = isEnabled;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to toggle alert rule: $e');
    }
  }

  // ─── DEVICES ──────────────────────────────────────────────────────────────

  Future<void> loadDevices() async {
    _setLoading(true);
    try {
      devices = await _deviceRepo.getAll();
      totalDevices = await _deviceRepo.getCount();
      activeDevices = await _deviceRepo.getActiveCount();
      inactiveDevices = await _deviceRepo.getInactiveCount();
    } catch (e) {
      _setError('Failed to load devices: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addDevice(AdminDevice device) async {
    try {
      await _deviceRepo.add(device);
      await loadDevices();
    } catch (e) {
      _setError('Failed to add device: $e');
    }
  }

  Future<void> updateDevice(AdminDevice device) async {
    try {
      await _deviceRepo.update(device);
      final index = devices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        devices[index] = device;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update device: $e');
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _deviceRepo.delete(deviceId);
      devices.removeWhere((d) => d.id == deviceId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete device: $e');
    }
  }

  Future<void> assignDevice(String deviceId, String patientId) async {
    try {
      await _deviceRepo.assign(deviceId, patientId);
      await loadDevices();
    } catch (e) {
      _setError('Failed to assign device: $e');
    }
  }

  Future<void> unassignDevice(String deviceId) async {
    try {
      await _deviceRepo.unassign(deviceId);
      await loadDevices();
    } catch (e) {
      _setError('Failed to unassign device: $e');
    }
  }

  // ─── USERS ────────────────────────────────────────────────────────────────

  Future<void> loadUsers() async {
    _setLoading(true);
    try {
      users = await _userRepo.getAll();
      totalUsers = await _userRepo.getCount();
    } catch (e) {
      _setError('Failed to load users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(AdminUser user) async {
    try {
      await _userRepo.update(user);
      final index = users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        users[index] = user;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update user: $e');
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _userRepo.toggleStatus(userId, isActive);
      final index = users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        users[index].isActive = isActive;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to toggle user status: $e');
    }
  }

  // ─── ASSIGNMENTS ──────────────────────────────────────────────────────────

  Future<void> loadAssignments() async {
    _setLoading(true);
    try {
      assignments = await _assignmentRepo.getAll();
    } catch (e) {
      _setError('Failed to load assignments: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> assignDoctor(String doctorId, String patientId) async {
    try {
      final success = await _assignmentRepo.assign(doctorId, patientId);
      if (success) {
        await loadAssignments();
      } else {
        _setError('Assignment already exists');
      }
    } catch (e) {
      _setError('Failed to assign doctor: $e');
    }
  }

  Future<void> removeAssignment(String doctorId, String patientId) async {
    try {
      await _assignmentRepo.remove(doctorId, patientId);
      assignments.removeWhere(
        (a) => a.doctorId == doctorId && a.patientId == patientId,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to remove assignment: $e');
    }
  }

  // ─── DASHBOARD ────────────────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadAlerts(),
        loadDevices(),
        loadUsers(),
      ]);
      totalAlertRules = alertRules.length;
    } catch (e) {
      _setError('Failed to load dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}