import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../repositories/auth_repository.dart';

class RealAuthRepository implements AuthRepository {
  RealAuthRepository(this._dio);
  final Dio _dio;

  AppUser? _currentUser;

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      final resp = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = resp.data['access_token'] as String;
      await saveToken(token);

      final meResp = await _dio.get('/auth/me');
      final user = AppUser.fromJson({
        ...meResp.data as Map<String, dynamic>,
        'organization_name': '',
      });
      _currentUser = user;
      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Ошибка подключения';
      throw Exception(msg);
    }
  }

  @override
  Future<void> logout() async {
    await deleteToken();
    _currentUser = null;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final token = await readToken();
    if (token == null) return null;
    try {
      final resp = await _dio.get('/auth/me');
      _currentUser = AppUser.fromJson({
        ...resp.data as Map<String, dynamic>,
        'organization_name': '',
      });
      return _currentUser;
    } catch (_) {
      return null;
    }
  }
}
