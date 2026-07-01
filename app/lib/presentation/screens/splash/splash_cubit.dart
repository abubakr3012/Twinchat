import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/token_storage.dart';
import '../../router/app_router.dart';

/// SplashCubit — проверяет токен и инициирует навигацию.
class SplashCubit extends Cubit<void> {
  SplashCubit({
    required TokenStorage storage,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _storage = storage,
        _navigatorKey = navigatorKey,
        super(null);

  factory SplashCubit.fromDi() => SplashCubit(
        storage: GetIt.I<TokenStorage>(),
        navigatorKey: GetIt.I<AppRouter>().navigatorKey,
      );

  final TokenStorage _storage;
  final GlobalKey<NavigatorState> _navigatorKey;

  Future<void> checkToken() async {
    final loggedIn = await _storage.hasAccess();
    // Give the widget tree time to mount before navigating
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (isClosed) return;
    // Retry navigation a few times in case router isn't ready yet
    for (int attempt = 0; attempt < 10; attempt++) {
      final ctx = _navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          final router = GoRouter.of(ctx);
          if (loggedIn) {
            router.go('/chats');
          } else {
            router.go('/login');
          }
          return;
        } catch (_) {
          // Router not ready yet, wait and retry
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (isClosed) return;
    }
  }
}