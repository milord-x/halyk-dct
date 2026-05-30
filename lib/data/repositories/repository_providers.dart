import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'auth_repository.dart';
import 'order_repository.dart';
import 'session_repository.dart';
import '../mock/mock_auth_repository.dart';
import '../mock/mock_order_repository.dart';
import '../mock/mock_session_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.useMock) return MockAuthRepository();
  // TODO: return RealAuthRepository(ref.read(dioProvider));
  throw UnimplementedError('Real auth repository not implemented yet');
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (AppConstants.useMock) return MockOrderRepository();
  // TODO: return RealOrderRepository(ref.read(dioProvider));
  throw UnimplementedError('Real order repository not implemented yet');
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (AppConstants.useMock) return MockSessionRepository();
  // TODO: return RealSessionRepository(ref.read(dioProvider));
  throw UnimplementedError('Real session repository not implemented yet');
});
