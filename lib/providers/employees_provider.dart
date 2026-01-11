import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/employee.dart';
import '../data/repositories/employee_repository.dart';

// Employee repository provider
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

// All employees provider
final employeesNotifierProvider = AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(() {
  return EmployeesNotifier();
});

class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() async {
    try {
      return await EmployeeRepository().getAll();
    } catch (e, _) {
      // Re-throw to let AsyncValue handle the error state
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final employees = await EmployeeRepository().getAll();
      state = AsyncData(employees);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addEmployee(Employee employee) async {
    await EmployeeRepository().insert(employee);
    await refresh();
  }

  Future<void> updateEmployee(Employee employee) async {
    await EmployeeRepository().update(employee);
    await refresh();
  }

  Future<void> deleteEmployee(String id) async {
    await EmployeeRepository().delete(id);
    await refresh();
  }
}

// Current logged in employee provider
final currentEmployeeProvider = StateProvider<Employee?>((ref) => null);

// Employee by PIN provider
final employeeByPinProvider = FutureProvider.family<Employee?, String>((ref, pin) async {
  return await EmployeeRepository().getByPin(pin);
});

// Employee count provider
final employeeCountProvider = FutureProvider<int>((ref) async {
  return await EmployeeRepository().getActiveEmployeeCount();
});

// Employees by role provider
final employeesByRoleProvider = FutureProvider.family<List<Employee>, EmployeeRole>((ref, role) async {
  return await EmployeeRepository().getByRole(role);
});

// PIN validation provider
final isPinUniqueProvider = FutureProvider.family<bool, ({String pin, String? excludeId})>((ref, params) async {
  return await EmployeeRepository().isPinUnique(params.pin, excludeId: params.excludeId);
});
