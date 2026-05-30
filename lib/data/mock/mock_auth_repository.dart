import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

const _mockUsers = [
  {
    'id': 'user-001',
    'organization_id': 'org-store-001',
    'email': 'store1@halyk.kz',
    'password': '1234',
    'role': 'store',
    'full_name': 'Магазин №1 — Алматы',
    'organization_name': 'Магазин №1',
  },
  {
    'id': 'user-002',
    'organization_id': 'org-store-002',
    'email': 'store2@halyk.kz',
    'password': '1234',
    'role': 'store',
    'full_name': 'Магазин №2 — Астана',
    'organization_name': 'Магазин №2',
  },
];

class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final data = _mockUsers.where(
      (u) => u['email'] == email && u['password'] == password,
    );
    if (data.isEmpty) throw Exception('Неверный email или пароль');
    _currentUser = AppUser.fromJson(data.first);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;
}
