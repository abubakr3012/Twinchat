import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_constants.dart';
import '../core/api/dio_client.dart';
import '../core/crypto/key_manager.dart';
import '../core/storage/token_storage.dart';
import '../data/datasources/attachments_remote.dart';
import '../data/datasources/auth_remote.dart';
import '../data/datasources/calls_remote.dart';
import '../data/datasources/chats_remote.dart';
import '../data/datasources/contacts_remote.dart';
import '../data/datasources/encryption_remote.dart';
import '../data/datasources/messages_remote.dart';
import '../data/datasources/reactions_remote.dart';
import '../data/datasources/settings_remote.dart';
import '../data/datasources/stories_remote.dart';
import '../data/datasources/users_remote.dart';
import '../data/repositories/attachments_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/calls_repository_impl.dart';
import '../data/repositories/chats_repository_impl.dart';
import '../data/repositories/contacts_repository_impl.dart';
import '../data/repositories/encryption_repository_impl.dart';
import '../data/repositories/messages_repository_impl.dart';
import '../data/repositories/reactions_repository_impl.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../data/repositories/stories_repository_impl.dart';
import '../data/repositories/users_repository_impl.dart';
import '../domain/repositories/attachments_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/calls_repository.dart';
import '../domain/repositories/chats_repository.dart';
import '../domain/repositories/contacts_repository.dart';
import '../domain/repositories/encryption_repository.dart';
import '../domain/repositories/messages_repository.dart';
import '../domain/repositories/reactions_repository.dart';
import '../domain/repositories/settings_repository.dart';
import '../domain/repositories/stories_repository.dart';
import '../domain/repositories/users_repository.dart';
import '../presentation/router/app_router.dart';

final GetIt getIt = GetIt.instance;

/// Инициализация зависимостей.
Future<void> configureDependencies() async {
  // --- Внешние зависимости ---
  const secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  getIt.registerSingleton<FlutterSecureStorage>(secure);
  getIt.registerSingleton<TokenStorage>(TokenStorage(secure));
  getIt.registerSingleton<KeyManager>(KeyManager(secure));

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // --- Сеть ---
  final tokenStorage = getIt<TokenStorage>();
  final dioClient = DioClient.create(
    storage: secure,
    tokenStorage: tokenStorage,
    onError: (msg) {
      // ignore: avoid_print
      print('[dio] $msg');
    },
    onAuthFailure: () async {
      // Refresh окончательно провалился — чистим токены и уводим на экран входа.
      await tokenStorage.clear();
      // Late-безопасное перенаправление: роутер может быть ещё не инициализирован.
      try {
        final router = getIt<AppRouter>();
        router.config.go('/phone');
      } catch (_) {
        // ignore — роутер ещё не зарегистрирован
      }
    },
  );
  getIt.registerSingleton<DioClient>(dioClient);
  final dio = dioClient.dio;

  // --- Remotes ---
  final authRemote = AuthRemoteDataSource(dio);
  final chatsRemote = ChatsRemote(dio);
  final messagesRemote = MessagesRemote(dio);
  final usersRemote = UsersRemote(dio);
  final contactsRemote = ContactsRemote(dio);
  final reactionsRemote = ReactionsRemote(dio);
  final attachmentsRemote = AttachmentsRemote(dio);
  final callsRemote = CallsRemote(dio);
  final storiesRemote = StoriesRemote(dio);
  final settingsRemote = SettingsRemote(dio);
  final encryptionRemote = EncryptionRemote(dio);

  getIt.registerSingleton<AuthRemoteDataSource>(authRemote);
  getIt.registerSingleton<ChatsRemote>(chatsRemote);
  getIt.registerSingleton<MessagesRemote>(messagesRemote);
  getIt.registerSingleton<UsersRemote>(usersRemote);
  getIt.registerSingleton<ContactsRemote>(contactsRemote);
  getIt.registerSingleton<ReactionsRemote>(reactionsRemote);
  getIt.registerSingleton<AttachmentsRemote>(attachmentsRemote);
  getIt.registerSingleton<CallsRemote>(callsRemote);
  getIt.registerSingleton<StoriesRemote>(storiesRemote);
  getIt.registerSingleton<SettingsRemote>(settingsRemote);
  getIt.registerSingleton<EncryptionRemote>(encryptionRemote);

  // --- Repositories ---
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(remote: authRemote, tokenStorage: getIt<TokenStorage>()),
  );
  getIt.registerSingleton<ChatsRepository>(
    ChatsRepositoryImpl(chatsRemote),
  );
  getIt.registerSingleton<MessagesRepository>(
    MessagesRepositoryImpl(messagesRemote),
  );
  getIt.registerSingleton<UsersRepository>(
    UsersRepositoryImpl(usersRemote),
  );
  getIt.registerSingleton<ContactsRepository>(
    ContactsRepositoryImpl(contactsRemote),
  );
  getIt.registerSingleton<ReactionsRepository>(
    ReactionsRepositoryImpl(reactionsRemote),
  );
  getIt.registerSingleton<AttachmentsRepository>(
    AttachmentsRepositoryImpl(attachmentsRemote),
  );
  getIt.registerSingleton<CallsRepository>(
    CallsRepositoryImpl(callsRemote),
  );
  getIt.registerSingleton<StoriesRepository>(
    StoriesRepositoryImpl(storiesRemote, baseUrl: ApiConstants.baseUrl),
  );
  getIt.registerSingleton<SettingsRepository>(
    SettingsRepositoryImpl(settingsRemote),
  );
  getIt.registerSingleton<EncryptionRepository>(
    EncryptionRepositoryImpl(encryptionRemote),
  );

  // --- Роутер ---
  registerAppRouter(getIt, tokenStorage.hasAccess);
}