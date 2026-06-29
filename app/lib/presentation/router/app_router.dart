import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../screens/call/call_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chatlist/chat_list_screen.dart';
import '../screens/code/code_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/my_profile/my_profile_screen.dart';
import '../screens/phone/phone_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/register/register_screen.dart';
import '../screens/safe_mode/safe_mode_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/stories/stories_screen.dart';

/// Корневой роутер приложения.
class AppRouter {
  AppRouter._({
    required Future<bool> Function() hasToken,
    required this.navigatorKey,
  }) : _hasToken = hasToken;

  factory AppRouter.create({
    required Future<bool> Function() hasToken,
    required GlobalKey<NavigatorState> navigatorKey,
  }) =>
      AppRouter._(hasToken: hasToken, navigatorKey: navigatorKey);

  final Future<bool> Function() _hasToken;
  final GlobalKey<NavigatorState> navigatorKey;

  late final GoRouter config = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: _GoRouterRefresh(),
    redirect: (context, state) async {
      final loggedIn = await _hasToken();
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/phone' || loc == '/code' || loc == '/login' || loc == '/register';
      if (!loggedIn && !isAuthRoute) return '/phone';
      if (loggedIn && isAuthRoute) return '/chats';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/code',
        builder: (_, state) {
          final extra = state.extra;
          String? phone;
          String? dbg;
          if (extra is Map) {
            phone = extra['phone'] as String?;
            dbg = extra['debug_code'] as String?;
          }
          return CodeScreen(phoneNumber: phone, debugCode: dbg);
        },
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/chats', builder: (_, __) => const ChatListScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ChatScreen(chatId: id);
        },
      ),
      GoRoute(path: '/contacts', builder: (_, __) => const ContactsScreen()),
      GoRoute(path: '/stories', builder: (_, __) => const StoriesScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/safe-mode', builder: (_, __) => const SafeModeScreen()),
      GoRoute(path: '/my-profile', builder: (_, __) => const MyProfileScreen()),
      GoRoute(
        path: '/profile/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/call/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return CallScreen(chatId: id);
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Маршрут не найден: ${state.uri}')),
    ),
  );
}

/// Notifier, чтобы GoRouter пересчитал redirect.
class _GoRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

/// Удобный хелпер для регистрации в GetIt.
void registerAppRouter(GetIt getIt, Future<bool> Function() hasToken) {
  final key = GlobalKey<NavigatorState>();
  getIt.registerSingleton<GlobalKey<NavigatorState>>(key);
  getIt.registerSingleton<AppRouter>(
    AppRouter.create(hasToken: hasToken, navigatorKey: key),
  );
}