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
    // Чуть подождём, чтобы splash был виден (UX).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (isClosed) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final router = GoRouter.of(ctx);
    if (loggedIn) {
      router.go('/chats');
    } else {
      router.go('/login');
    }
  }
}