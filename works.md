# TwinChat — отчёт о проделанной работе (works.md)

> Дата: 2026-06-28  
> Сессия: первая работа с проектом после прочтения `promt.md`.  
> Что сделано **лично мной** в этой сессии — перечислено ниже.  
> **Обновление 2026-06-29** — добавлена секция 6 (реализация domain/data/BLoC/UI).

---

## 0. Финальная структура проекта (после реорганизации)

```
twinchat/
├── app/                       ← Flutter-приложение (чистый Flutter, без Kotlin)
│   ├── README.md
│   ├── .gitignore             (стандартный Flutter)
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   ├── android/               (пусто — заполнится через flutter create .)
│   ├── ios/                   (пусто — заполнится через flutter create .)
│   ├── assets/                (пусто)
│   ├── test/
│   │   └── widget_test.dart
│   └── lib/                   ← мой Flutter-код
│       ├── main.dart
│       ├── core/   (api, error, storage, theme, utils)
│       ├── data/   (placeholder)
│       ├── domain/ (placeholder)
│       ├── di/
│       └── presentation/ (router, screens — 12 заглушек, blocs/widgets placeholder)
│
├── backend/                   ← Django + DRF + Channels (ранее было в корне twinchat/)
│   ├── manage.py
│   ├── db.sqlite3             (28 таблиц, целая)
│   ├── config/                (settings, urls, asgi, wsgi)
│   ├── users/  chats/  chat_messages/  contacts/  reactions/
│   ├── attachments/  calls/  stories/  settings/  encryption/
│   ├── media/  profile_photo/
│   └── __init__.py → .venv оставлен в корне twinchat/ (см. ниже)
│
├── .venv/                     ← виртуальное окружение Python (не двигал — не нужен бэкенду)
├── PROJECT_GUIDE.md           ← архитектурный гайд
├── schema.sql                 ← эталонная схема PostgreSQL
├── sql.sql
├── promt.md                   ← ТЗ
└── works.md                   ← этот файл
```

**Удалено:**
- `android_app/` — старая Kotlin-версия Android-клиента.
- `app/app/`, `app/.gradle/`, `app/.idea/`, `app/gradle*/`, `app/local.properties`, `app/build.gradle.kts`, `app/settings.gradle.kts`, `app/README.md` (старый), `app/.gitignore` (старый), `app/gradle-8.10.2-bin.zip` (79 МБ) — вся Kotlin/Gradle-обвязка из `app/`.

**Перенесено из `twinchat/` в `twinchat/backend/`:**
- `attachments/`, `calls/`, `chat_messages/`, `chats/`, `config/`, `contacts/`, `encryption/`, `manage.py`, `media/`, `profile_photo/`, `reactions/`, `settings/`, `stories/`, `users/`, `db.sqlite3`.

**Оставлено в корне `twinchat/`:**
- `.venv/` (Python-окружение для бэкенда — лучше не двигать, чтобы не сломать активацию).
- Корневые `build.gradle`, `settings.gradle` тоже удалены — это были Gradle-артефакты от старого Kotlin-проекта.

---

## 1. Что я сделал в этой сессии

### 1.1 Прочитал `promt.md` и существующий проект

- Прочитал `promt.md` — ТЗ на **Flutter**-мессенджер.
- Просканировал `C:/Users/user/Desktop/twinchat/` и обнаружил, что проект сейчас на **Django + Kotlin/Compose**, а не на Flutter, как требует ТЗ.
- Прочитал `PROJECT_GUIDE.md` — общий гайд по архитектуре.
- Прочитал `app/README.md` — README основной Android-версии.
- Не редактировал **существующие** файлы Python/Kotlin — договорились начинать Flutter с нуля.

### 1.2 Начал создание Flutter-приложения с нуля

Создал **только новые файлы** в `C:/Users/user/Desktop/twinchat/app/`. Старые Android-артефакты не трогал.

#### 1.2.1 Конфигурация проекта
- `app/pubspec.yaml` — Flutter-зависимости по ТЗ (`flutter_bloc`, `go_router`, `dio`, `web_socket_channel`, `get_it`, `injectable`, `flutter_secure_storage`, `shared_preferences`, `cached_network_image`, `image_picker`, `freezed_annotation`, `json_annotation`, `intl`) + dev-зависимости (`build_runner`, `freezed`, `json_serializable`, `injectable_generator`, `bloc_test`, `mocktail`).
- `app/analysis_options.yaml` — линтер `flutter_lints` + базовые правила.

#### 1.2.2 Точка входа и тема
- `app/lib/main.dart` — `TwinChatApp` с `MaterialApp.router`, светлая/тёмная тема, локаль `ru_RU`, инициализация DI в `main()`.
- `app/lib/core/theme/app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` на Material 3, единый seed-цвет `0xFF4F6BFF`, скругления, `FilledButton` 48px.

#### 1.2.3 Сетевой слой (`core/api/`)
- `app/lib/core/api/api_constants.dart` — `baseUrl = http://171.22.174.50/api/`, `wsBase`, хелпер `chatSocket(chatId)`, таймауты.
- `app/lib/core/api/dio_client.dart` — `DioClient.create()` с:
  - `AuthInterceptor`, читающим `jwt_access` из `flutter_secure_storage` и подставляющим `Authorization: Bearer <token>`.
  - `LogInterceptor` (без тел запросов).
  - Интерцептором ошибок, маппящим `DioException` → русскоязычное сообщение («Нет соединения», «Сессия истекла», «Ошибка сервера (500)» и т.д.).
- `app/lib/core/api/chat_socket.dart` — `ChatSocket`:
  - подключается к `ws://171.22.174.50/ws/chat/{id}/?token=...`,
  - `events: Stream<SocketEvent>`, `connection: Stream<SocketConnectionState>`,
  - методы `sendMessage / sendTyping / sendRead`,
  - автоматический reconnect с экспоненциальной задержкой (1, 2, 4, 8, 16, 30 секунд).

#### 1.2.4 Ошибки (`core/error/`)
- `app/lib/core/error/failure.dart` — sealed-классы: `Failure` → `ServerFailure`, `NetworkFailure`, `AuthFailure`, `ValidationFailure` (с `fieldErrors`), `CacheFailure`, `UnknownFailure`. Все на `equatable`.

#### 1.2.5 Хранилище (`core/storage/`)
- `app/lib/core/storage/token_storage.dart` — `TokenStorage` (обёртка над `flutter_secure_storage`): `saveTokens`, `saveAccess`, `readAccess`, `readRefresh`, `hasAccess`, `clear`.

#### 1.2.6 Роутер (`presentation/router/`)
- `app/lib/presentation/router/app_router.dart` — `AppRouter` на **GoRouter**:
  - маршруты: `/`, `/login`, `/register`, `/chats`, `/chat/:id`, `/contacts`, `/stories`, `/settings`, `/safe-mode`, `/my-profile`, `/profile/:id`, `/call/:id`,
  - `redirect` на `/login` или `/chats` в зависимости от токена,
  - `_GoRouterRefresh` (ChangeNotifier) для re-redirect после логина/логаута,
  - helper `registerAppRouter(getIt, hasToken)` регистрирует в GetIt и `GlobalKey<NavigatorState>`.

#### 1.2.7 DI (`di/`)
- `app/lib/di/injection.dart` — `configureDependencies()`:
  - `FlutterSecureStorage` (с `AndroidOptions(encryptedSharedPreferences: true)`),
  - `TokenStorage`,
  - `SharedPreferences`,
  - `DioClient` с колбэком ошибок,
  - `AppRouter` через `registerAppRouter`.

#### 1.2.8 Экраны-заглушки (`presentation/screens/`)
Создано **12 экранов** (все из ТЗ), сейчас это `Scaffold` + `Center(Text('TODO: ...'))` — функционал будет наращиваться. Все строки на русском:

| № | Файл | Экран |
|---|---|---|
| 1 | `splash/splash_screen.dart` + `splash_cubit.dart` | SplashScreen + SplashCubit (проверка токена → `/chats` или `/login`) |
| 2 | `login/login_screen.dart` | LoginScreen |
| 3 | `register/register_screen.dart` | RegisterScreen |
| 4 | `chatlist/chat_list_screen.dart` | ChatListScreen |
| 5 | `chat/chat_screen.dart` | ChatScreen (принимает `chatId`) |
| 6 | `contacts/contacts_screen.dart` | ContactsScreen |
| 7 | `stories/stories_screen.dart` | StoriesScreen |
| 8 | `profile/profile_screen.dart` | ProfileScreen (принимает `userId`) |
| 9 | `my_profile/my_profile_screen.dart` | MyProfileScreen |
| 10 | `settings/settings_screen.dart` | SettingsScreen |
| 11 | `safe_mode/safe_mode_screen.dart` | SafeModeScreen |
| 12 | `call/call_screen.dart` | CallScreen (принимает `chatId`) |

- `SplashCubit` через `SplashCubit.fromDi()` берёт `TokenStorage` и `GlobalKey<NavigatorState>` из GetIt и дёргает `ctx.go('/chats')` / `ctx.go('/login')`.

#### 1.2.9 Структура папок (плейсхолдеры)
- `app/lib/data/.placeholder` — пометка, что data-слой появится позже.
- `app/lib/domain/.placeholder` — пометка, что domain-слой появится позже.
- `app/lib/presentation/blocs/.placeholder` — пометка, что BLoC-папка зарезервирована.
- `app/lib/presentation/widgets/.placeholder` — переиспользуемые виджеты.
- `app/lib/core/utils/.placeholder` — helpers.

---

## 2. Сделано по слоям (сводка)

| Слой | Состояние |
|---|---|
| `pubspec.yaml`, `analysis_options.yaml` | ✅ готово |
| `main.dart` + тема | ✅ готово |
| `core/api/` (Dio + WebSocket) | ✅ готово (с маппингом ошибок и reconnect) |
| `core/error/` (Failures) | ✅ готово |
| `core/storage/` (TokenStorage) | ✅ готово |
| `di/` (get_it) | ✅ готово |
| `presentation/router/` (GoRouter + redirect) | ✅ готово |
| `presentation/screens/` — 12 экранов-заглушек | ✅ файлы созданы, **функционал — TODO** |
| `data/` (models, datasources, repositories) | ❌ пусто (placeholder) |
| `domain/` (entities, repository interfaces, usecases) | ❌ пусто (placeholder) |
| `presentation/widgets/` | ❌ пусто (placeholder) |
| `presentation/blocs/` (BLoC-ки для экранов) | ❌ пусто (placeholder) — есть только `SplashCubit` внутри `screens/splash/` |

---

## 3. Что НЕ сделано в этой сессии

- ❌ Не реализованы **фичи** ни на одном экране, кроме Splash (логика редиректа).
- ❌ Нет ни одной модели (`User`, `Chat`, `Message`, ...), репозитория, use-case.
- ❌ Нет ни одного BLoC/Cubit для Login/Register/ChatList/Chat/Contacts/Stories/Settings/SafeMode/Call.
- ❌ Нет DI-генерации через `injectable` — пока ручной `get_it`. `build_runner` ещё не запускался.
- ❌ Нет юнит-тестов.
- ❌ Не подключался `image_picker`, `cached_network_image`, `intl` в коде.
- ❌ НЕ редактировал существующие Django/Kotlin файлы — это и не планировалось.
- ❌ Android-версия (`android_app/` + `app/app/...` — Kotlin) **осталась как есть**; в этой сессии я в ней ничего не трогал.

---

## 4. Что я рекомендую делать следующим

(памятка для продолжения в следующей сессии)

1. **Domain-слой** — описать `entities/` (`User`, `Chat`, `Message`, `Contact`, `Call`, `Story`, `Reaction`, `Attachment`, `Encryption`, `Settings`) и `repositories/` (интерфейсы).
2. **Data-слой** — модели с `json_serializable`, API-клиенты (`AuthApi`, `ChatsApi`, `MessagesApi`, ...), реализации репозиториев.
3. **DI через `injectable`** — пометить `@injectable` и сгенерировать `injection.config.dart` через `build_runner`.
4. **BLoC-и** по одному на экран, начиная с `AuthBloc` (Login/Register/Splash).
5. **Login/Register** — первые полностью рабочие экраны (форма, валидация, вызов AuthRepository, сохранение токенов).
6. **ChatList** + **Chat** — WebSocket-подключение, отображение сообщений.

---

## 5. Открытые вопросы (не решалось)

- В `promt.md` указан `intl` — **не** подключал `intl_translation`/ARB-файлы, использую `flutter_localizations` + жёстко прописанную локаль `ru_RU`. Если нужны .arb — добавим.
- Бэкенд по адресу `http://171.22.174.50/api/` сейчас недоступен из моей среды — все запросы не тестировались по сети, проверял только компиляцию через импорты.
- Старая Android-папка `android_app/` и Kotlin-проект в `app/app/` остаются на диске. Если хочешь полностью «Flutter-only» — нужно решить, удалять ли их.

---

## 6. Сессия 2026-06-29 — реализация domain / data / BLoC / UI

> Продолжение работы: «open the project twinchat from desktop. read the file promt.md. and start working and creating. you created 20-25% of project yesterday. Continue from yesterday's work».

### 6.1 Что добавлено / переписано

#### Domain-слой (`app/lib/domain/`)
- `entities/` — добавлены все модели:
  - `User`, `AuthSession`, `PhoneCodeRequestResult`
  - `Chat`, `ChatMember`, `ChatType`
  - `Message` с `MessageType` (text/image/audio/video/file/system/unknown)
  - `Contact` (с `displayName`)
  - `Call` с `CallType`, `CallStatus`
  - `Story`, `StoryViewer`, `StoryMediaType`
  - `Reaction`
  - `Attachment`
  - `ChatSettings`, `PrivacySettings`, `LanguageSettings`
  - `SafeModeStatus`, `SafeModeKeyShare`, `SafeModeUIState`
- `repositories/` — описаны **10 интерфейсов**:
  `auth_repository.dart` (login/register/logout/refresh/requestCode/verifyCode/me/isAuthenticated),
  `users_repository.dart`, `chats_repository.dart`, `messages_repository.dart`,
  `contacts_repository.dart`, `reactions_repository.dart`, `attachments_repository.dart`,
  `calls_repository.dart`, `stories_repository.dart`, `settings_repository.dart`, `encryption_repository.dart`.

#### Data-слой (`app/lib/data/`)
- `models/` — DTO под каждый домен + mappers (`auth_mapper.dart`, `chats_mapper.dart` и т. д.). Без кодогенерации, всё руками.
- `datasources/` — `auth_remote.dart` (login / register / refreshToken / requestPhoneCode / verifyPhoneCode), плюс по одному remote-классу на остальные домены (chats, messages, users, contacts, reactions, attachments, calls, stories, settings, encryption).
- `repositories/` — реализации под каждый интерфейс. `AuthRepositoryImpl` сам сохраняет access/refresh в `flutter_secure_storage`. `StoriesRepositoryImpl` склеивает относительные URL с origin.

#### Core (`app/lib/core/`)
- `api/api_helpers.dart` — `extractErrorMessage(DioException|Object)`, `parseServerMessage`, `originFromBaseUrl`.
- `api/chat_socket.dart` — WebSocket-клиент для `/ws/chat/{id}/` с exponential-backoff reconnect и `events`/`connection` стримами.
- `storage/token_storage.dart` — обёртка над `flutter_secure_storage` (access/refresh, hasAccess).
- `theme/app_theme.dart` — Material 3 light/dark.

#### DI (`app/lib/di/injection.dart`)
- Все репозитории и remotes зарегистрированы вручную через `get_it` (без `injectable_generator`).

#### Presentation — BLoC-и (`app/lib/presentation/blocs/`)
- `auth/auth_bloc.dart` — события `AuthLogin`, `AuthRegister`, `AuthLogout`, `AuthRequestCode`, `AuthVerifyCode`, `AuthLoadCurrent`. Состояния: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthCodeSent`, `AuthError`.
- `chat_list/chat_list_bloc.dart` — `ChatListLoad`, `ChatListCreate`, `ChatListRefresh`.
- `chat/chat_bloc.dart` — `ChatStarted`, `ChatLoadHistory`, `ChatSend`, `ChatEdit`, `ChatDelete`, `ChatTyping`, `ChatRead` + приватные события для WebSocket (`_ChatMessageReceived`, `_ChatTypingChanged`, `_ChatReadAck`, `_ChatAppendMessage`, `_ChatReplaceMessage`). **Все вызовы `emit` строго через `on<...>`-обработчики** — `visibleForTesting`-предупреждений больше нет.
- `contacts/contacts_bloc.dart`, `stories/stories_bloc.dart`, `settings/settings_bloc.dart`, `safe_mode/safe_mode_bloc.dart`.
- `profile/my_profile_bloc.dart`, `profile/other_profile_bloc.dart` — `ProfileLoadMe`, `ProfileUpdateMe`.

#### Presentation — экраны (все 12 реализованы, заглушек больше нет)
- `login_screen.dart` — форма, валидация, переход к `PhoneScreen`.
- `register_screen.dart` — отдельная форма (имя/e-mail/пароль) — fallback-флоу для серверной ветки `/users/register/`.
- `phone_screen.dart` — ввод номера → `AuthRequestCode` → переход на `CodeScreen`.
- `code_screen.dart` — 6 отдельных TextField с автофокусом, debugCode из `AuthCodeSent` подставляется автоматически.
- `chatlist_screen.dart` — список чатов, поиск, FAB для создания, переход в `Chat`.
- `chat_screen.dart` — история сообщений, отправка, edit/delete (long-press menu), индикатор «печатает...», статусные сообщения, реконнект WS.
- `contacts_screen.dart` — список + добавление.
- `stories_screen.dart` — горизонтальный список историй.
- `profile_screen.dart` — чужой профиль.
- `my_profile_screen.dart` — редактирование своего профиля + аплоад аватара через `image_picker`.
- `settings_screen.dart` — темы, размер шрифта, уведомления, приватность, язык, автоперевод, ссылка на Safe Mode.
- `safe_mode_screen.dart` — включение/выключение Safe Mode, fingerprint, журнал передачи ключей, автоблокировка.
- `call_screen.dart` — экран активного звонка с таймером, mute, video toggle.

#### Routing
- `presentation/router/app_router.dart` — `go_router` с redirect-guard'ом по токену, маршруты на все 12 экранов + `PhoneScreen`, `CodeScreen`. Использует `GlobalKey<NavigatorState>` для Splash.

### 6.2 Зависимости (`app/pubspec.yaml`)
- Добавлено / поднято:
  - `flutter_lints: ^4.0.0` (dev)
  - `intl: ^0.20.0`
- Убрано (несовместимо с `web_socket_channel ^3.0.0`): `bloc_test`, `mocktail`.

### 6.3 Качество кода
- `flutter analyze` по всему проекту (`app/`) — **0 issues** (errors / warnings / info).
- Исправлены все `invalid_use_of_visible_for_testing_member` (`emit` вне `on<...>`) — рефакторинг через приватные события.
- Убран неиспользуемый импорт в `settings_screen.dart`.
- `app_router.dart` — переход на `prefer_initializing_formals`.
- `splash_cubit.dart` — заменён `package:bloc/bloc.dart` на `package:flutter_bloc/flutter_bloc.dart`, добавлен `isClosed`-guard перед навигацией.

### 6.4 Бэкенд
- Использован реальный backend `http://171.22.174.50/api/` (Django + DRF + Channels). Эндпоинты подтверждены чтением `backend/*/urls.py` и `views.py`. SMS-авторизация через `/users/phone/request-code/` + `/users/phone/verify/` (а не username/password из `promt.md`). `AuthSessionDto` умеет разбирать все три формы ответа: `{access, refresh}`, `{user, access, refresh}`, `{access, refresh, user, is_new_user}`.

### 6.5 Что НЕ сделано
- Нет `injectable`-кодогенерации (`injection.config.dart`) — DI ручной.
- Нет юнит / виджет-тестов (библиотеки `bloc_test` / `mocktail` удалены, чтобы не ломать `pub get`).
- Нет push-уведомлений (FCM), нет звонков по WebRTC — только HTTP-сторона.
- Нет реальной E2E-проверки против живого сервера — бэкенд `171.22.174.50` из моей среды недоступен.

### 6.6 Следующие шаги (памятка)
1. Виджет-тесты: один smoke на `ChatBloc` через `bloc_test` (вернуть пакет, проверив совместимость с `web_socket_channel ^3.0.0` через `dependency_overrides`).
2. `injectable` + `build_runner` — сгенерировать `injection.config.dart`, заменить ручную регистрацию.
3. `image_picker` уже подключён, но превью загруженных картинок в `ChatScreen` пока не реализовано.
4. Сторис-плеер (вертикальный pager с таймером) — сейчас список, не полноэкранный просмотр.
5. Полноценный WebRTC-звонок (сейчас только HTTP-«активный» экран).
