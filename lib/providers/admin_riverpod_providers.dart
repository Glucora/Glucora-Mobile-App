import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/admin_model.dart';
import '../services/repositories/alert_repository.dart';
import '../services/repositories/assignment_repository.dart';
import '../services/repositories/device_repository.dart';
import '../services/repositories/user_repository.dart';

// ─── REPOSITORIES (created once, reused) ─────────────────────────────────────

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(Supabase.instance.client);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(Supabase.instance.client);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(Supabase.instance.client);
});

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(Supabase.instance.client);
});

// ─── STATE CLASSES ────────────────────────────────────────────────────────────

class AdminUsersState {
  final List<AdminUser> users;
  final int totalUsers;
  final bool isLoading;
  final String? error;

  const AdminUsersState({
    this.users = const [],
    this.totalUsers = 0,
    this.isLoading = false,
    this.error,
  });

  AdminUsersState copyWith({
    List<AdminUser>? users,
    int? totalUsers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      totalUsers: totalUsers ?? this.totalUsers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AdminDevicesState {
  final List<AdminDevice> devices;
  final int totalDevices;
  final int activeDevices;
  final int inactiveDevices;
  final bool isLoading;
  final String? error;

  const AdminDevicesState({
    this.devices = const [],
    this.totalDevices = 0,
    this.activeDevices = 0,
    this.inactiveDevices = 0,
    this.isLoading = false,
    this.error,
  });

  AdminDevicesState copyWith({
    List<AdminDevice>? devices,
    int? totalDevices,
    int? activeDevices,
    int? inactiveDevices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminDevicesState(
      devices: devices ?? this.devices,
      totalDevices: totalDevices ?? this.totalDevices,
      activeDevices: activeDevices ?? this.activeDevices,
      inactiveDevices: inactiveDevices ?? this.inactiveDevices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AdminAlertsState {
  final List<AdminAlert> alerts;
  final bool isLoading;
  final String? error;

  const AdminAlertsState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  AdminAlertsState copyWith({
    List<AdminAlert>? alerts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminAlertsState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─── NOTIFIERS ────────────────────────────────────────────────────────────────

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final UserRepository _repo;

  AdminUsersNotifier(this._repo) : super(const AdminUsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final users = await _repo.getAll();
      final total = await _repo.getCount();
      state = state.copyWith(users: users, totalUsers: total, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load users: $e',
      );
    }
  }

  Future<void> deleteUser(String userId, String role) async {
    try {
      await _repo.deleteUser(userId, role);
      state = state.copyWith(
        users: state.users.where((u) => u.id != userId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete user: $e');
    }
  }

  Future<void> updateUserRoleAndStatus(
      String userId, String role, bool isActive) async {
    try {
      await _repo.updateUserRoleAndStatus(userId, role, isActive);
      state = state.copyWith(
        users: state.users.map((u) {
          return u.id == userId ? u.copyWith(role: role, isActive: isActive) : u;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update user: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

class AdminDevicesNotifier extends StateNotifier<AdminDevicesState> {
  final DeviceRepository _repo;

  AdminDevicesNotifier(this._repo) : super(const AdminDevicesState());

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final devices = await _repo.getAll();
      final total = await _repo.getCount();
      final active = await _repo.getActiveCount();
      final inactive = await _repo.getInactiveCount();
      state = state.copyWith(
        devices: devices,
        totalDevices: total,
        activeDevices: active,
        inactiveDevices: inactive,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load devices: $e',
      );
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _repo.delete(deviceId);
      state = state.copyWith(
        devices: state.devices.where((d) => d.id != deviceId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete device: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

class AdminAlertsNotifier extends StateNotifier<AdminAlertsState> {
  final AlertRepository _repo;

  AdminAlertsNotifier(this._repo) : super(const AdminAlertsState());

  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final alerts = await _repo.getAll();
      state = state.copyWith(alerts: alerts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load alerts: $e',
      );
    }
  }

  Future<void> deleteAlert(int id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
        alerts: state.alerts.where((a) => a.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete alert: $e');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ─── PROVIDER INSTANCES ───────────────────────────────────────────────────────

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  return AdminUsersNotifier(ref.watch(userRepositoryProvider));
});

final adminDevicesProvider =
    StateNotifierProvider<AdminDevicesNotifier, AdminDevicesState>((ref) {
  return AdminDevicesNotifier(ref.watch(deviceRepositoryProvider));
});

final adminAlertsProvider =
    StateNotifierProvider<AdminAlertsNotifier, AdminAlertsState>((ref) {
  return AdminAlertsNotifier(ref.watch(alertRepositoryProvider));
});

// ─── DASHBOARD (combines all 3) ───────────────────────────────────────────────

final adminDashboardProvider = Provider((ref) {
  final users = ref.watch(adminUsersProvider);
  final devices = ref.watch(adminDevicesProvider);
  final alerts = ref.watch(adminAlertsProvider);
  return (users: users, devices: devices, alerts: alerts);
});