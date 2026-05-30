import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/providers/auth_provider.dart';

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  return ref.read(orderRepositoryProvider).getOrdersForStore(user.organizationId);
});

final orderDetailProvider = FutureProvider.family<Order, String>((ref, orderId) async {
  return ref.read(orderRepositoryProvider).getOrderById(orderId);
});
