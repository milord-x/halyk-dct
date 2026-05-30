import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../network/api_client.dart';
import 'auth_repository.dart';
import 'order_repository.dart';
import 'session_repository.dart';
import '../mock/mock_auth_repository.dart';
import '../mock/mock_order_repository.dart';
import '../mock/mock_session_repository.dart';
import '../real/real_auth_repository.dart';
import '../real/real_order_repository.dart';
import '../real/real_session_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.useMock) return MockAuthRepository();
  return RealAuthRepository(ref.read(dioProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (AppConstants.useMock) return MockOrderRepository();
  return RealOrderRepository(ref.read(dioProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (AppConstants.useMock) return MockSessionRepository();
  return RealSessionRepository(ref.read(dioProvider));
});

// Провайдер для recognize-image (только реальный)
final realSessionRepoProvider = Provider<RealSessionRepository?>((ref) {
  if (AppConstants.useMock) return null;
  return RealSessionRepository(ref.read(dioProvider));
});
