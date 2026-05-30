import '../models/user_model.dart';

abstract class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
}
