import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/locale_provider.dart';
import 'core/utils/theme_mode_provider.dart';
import 'di/injection.dart';
import 'presentation/router/app_router.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await configureDependencies();
  await ThemeModeProvider.instance.init();

  runApp(const TwinChatApp());
}

class TwinChatApp extends StatefulWidget {
  const TwinChatApp({super.key});

  @override
  State<TwinChatApp> createState() => _TwinChatAppState();
}

class _TwinChatAppState extends State<TwinChatApp> {
  @override
  void initState() {
    super.initState();
    ThemeModeProvider.instance.addListener(_onThemeChanged);
    LocaleProvider.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    ThemeModeProvider.instance.removeListener(_onThemeChanged);
    LocaleProvider.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>();

    return MaterialApp.router(
      title: 'TwinChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeModeProvider.instance.themeMode,
      routerConfig: router.config,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: LocaleProvider.instance.locale,
    );
  }
}
