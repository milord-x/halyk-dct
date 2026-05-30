import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

const _tokenKey = 'jwt_token';

final _storage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.requestTimeout,
    receiveTimeout: AppConstants.requestTimeout,
    headers: {
      'Content-Type': 'application/json',
      ...AppConstants.ngrokHeaders,
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(error);
    },
  ));

  return dio;
});

// Сохранить токен после логина
Future<void> saveToken(String token) =>
    _storage.write(key: _tokenKey, value: token);

// Удалить токен при выходе
Future<void> deleteToken() => _storage.delete(key: _tokenKey);

// Прочитать токен
Future<String?> readToken() => _storage.read(key: _tokenKey);
