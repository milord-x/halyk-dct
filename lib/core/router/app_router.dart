import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/invoice/screens/invoice_camera_screen.dart';
import '../../features/invoice/screens/invoice_review_screen.dart';
import '../../features/acceptance/screens/discrepancy_screen.dart';
import '../../features/acceptance/screens/act_screen.dart';
import '../../features/acceptance/screens/acceptance_done_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (auth.isLoading) return null;
      final isLoggedIn = auth.isAuthenticated;
      final isLoginPage = state.uri.toString() == '/login';
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/orders';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/orders', builder: (context, _) => const OrdersScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/invoice-camera',
        builder: (context, state) =>
            InvoiceCameraScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/invoice-review',
        builder: (context, state) =>
            InvoiceReviewScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/discrepancies',
        builder: (context, state) =>
            DiscrepancyScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/act',
        builder: (context, state) =>
            ActScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/done',
        builder: (context, state) =>
            AcceptanceDoneScreen(orderId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Страница не найдена: ${state.error}')),
    ),
  );
});
