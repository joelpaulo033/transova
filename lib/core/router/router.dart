import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';
import '../../screens/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userValue = ref.watch(userProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: RouterRefreshListenable(ref),
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final path = state.matchedLocation;
      final isAuthPath = path == '/login';

      if (!isAuth) return isAuthPath ? null : '/login';
      if (isAuthPath) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return userValue.when(
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
            data: (user) => const DashboardScreen(),
          );
        },
      ),
    ],
  );
});

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProvider, (_, __) => notifyListeners());
  }
}
