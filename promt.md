# TwinChat — Flutter приложение

## Задача
Создай полноценное мобильное приложение мессенджера TwinChat на Flutter/Dart без вопросов. Сразу пиши весь код.

## Технологии
- Language: Dart
- UI: Flutter + Material Design 3 (flutter_material)
- Architecture: BLoC + Clean Architecture
- Navigation: go_router
- Network: dio (HTTP) + web_socket_channel (WebSocket)
- DI: get_it + injectable
- Async: Dart Streams + async/await
- Storage: flutter_secure_storage (токен), shared_preferences (настройки)
- Images: cached_network_image
- JWT: хранить в flutter_secure_storage, отправлять в заголовке Authorization: Bearer 

## Backend API
- Base URL: http://171.22.174.50/api/
- WebSocket URL: ws://171.22.174.50/ws/chat/{chat_id}/
- Аутентификация: JWT (SimpleJWT)
- Формат: JSON

## API Endpoints

### Auth (users)
- POST /api/users/register/ — {username, phone_number, password}
- POST /api/users/login/ — {username, password} → {access, refresh}
- POST /api/users/token/refresh/ — {refresh}
- GET /api/users/me/ — текущий пользователь
- PATCH /api/users/me/ — обновить профиль
- POST /api/users/logout/ — выход

### Chats
- GET /api/chats/ — список чатов
- POST /api/chats/ — создать {type, name}
- GET /api/chats/{id}/ — детали
- POST /api/chats/{id}/members/ — добавить участника

### Messages
- GET /api/messages/?chat={id} — история
- POST /api/messages/ — отправить {chat, content, message_type}
- PATCH /api/messages/{id}/ — редактировать
- DELETE /api/messages/{id}/ — удалить

### Contacts
- GET /api/contacts/
- POST /api/contacts/ — {contact, nickname}
- DELETE /api/contacts/{id}/
- POST /api/contacts/{id}/block/
- POST /api/contacts/{id}/unblock/

### Attachments
- POST /api/attachments/upload/ — multipart
- GET /api/attachments/?message={id}

### Reactions
- GET /api/reactions/?message={id}
- POST /api/reactions/ — {message, emoji}
- DELETE /api/reactions/{id}/

### Calls
- GET /api/calls/
- POST /api/calls/ — {chat, call_type}
- POST /api/calls/{id}/accept/
- POST /api/calls/{id}/reject/
- POST /api/calls/{id}/end/

### Stories
- GET /api/stories/
- POST /api/stories/ — multipart
- GET /api/stories/my/
- DELETE /api/stories/{id}/
- GET /api/stories/{id}/viewers/

### Settings
- GET/PATCH /api/settings/chat/ — {theme, text_size, notifications}
- GET/PATCH /api/settings/privacy/
- GET/PATCH /api/settings/language/

### Encryption (Safe Mode)
- GET /api/encryption/status/
- POST /api/encryption/enable/ — {encrypted_key, key_fingerprint}
- POST /api/encryption/disable/
- GET/PATCH /api/encryption/ui/ — {key_entered, auto_lock_minutes}

## WebSocket события

### Клиент → Сервер
{"type": "message", "content": "текст", "message_type": "text"}
{"type": "typing", "is_typing": true}
{"type": "read", "message_id": 42}

### Сервер → Клиент
{"type": "message", "message_id": 1, "content": "...", "sender_id": 2, "sender_username": "john", "sent_at": "..."}
{"type": "typing", "user_id": 2, "username": "john", "is_typing": true}
{"type": "read", "message_id": 42, "user_id": 2}
{"type": "online", "user_id": 2, "username": "john"}
{"type": "offline", "user_id": 2, "username": "john"}

## Экраны

### 1. SplashScreen
- Проверка токена в flutter_secure_storage
- Токен есть → ChatListScreen, нет → LoginScreen

### 2. LoginScreen
- Поля: username, password
- Кнопка войти, ссылка на RegisterScreen
- При успехе → сохранить токен → ChatListScreen

### 3. RegisterScreen
- Поля: username, phone_number, password, confirm_password
- При успехе → LoginScreen

### 4. ChatListScreen (главный экран)
- BottomNavigationBar: Чаты | Контакты | Истории | Настройки
- Список чатов: аватар, имя, последнее сообщение, время, счётчик непрочитанных
- FloatingActionButton создать чат
- Нажатие → ChatScreen

### 5. ChatScreen
- AppBar: аватар, имя, статус онлайн
- ListView.builder для сообщений
- Статусы: отправлено / доставлено / прочитано (галочки)
- Типы: text, image, audio, video, file
- Long press → BottomSheet (ответить, редактировать, удалить, реакции)
- Поле ввода + отправить + прикрепить файл (file_picker)
- WebSocket при открытии экрана
- "Печатает..." индикатор

### 6. ContactsScreen
- Список контактов
- Поиск по имени/username
- Кнопка добавить контакт
- Нажатие → ProfileScreen
- Dismissible (свайп) → удалить / заблокировать

### 7. StoriesScreen
- Горизонтальный ListView аватаров с историями
- Нажатие → полноэкранный просмотр с LinearProgressIndicator (24 ч)
- FAB → image_picker для добавления истории

### 8. ProfileScreen (чужой)
- Аватар, имя, статус
- Кнопки: написать, позвонить (voice/video)
- Телефон, bio

### 9. MyProfileScreen
- CircleAvatar с кнопкой изменить (image_picker)
- Имя, username, телефон, bio
- Кнопка редактировать

### 10. SettingsScreen
- Тема: light / dark / system (ThemeMode)
- Размер текста
- Уведомления вкл/выкл
- Приватность: кто видит номер/фото/статус, автоудаление
- Язык
- Safe Mode (переход на SafeModeScreen)
- Кнопка Выйти

### 11. SafeModeScreen
- Статус вкл/выкл
- Fingerprint ключа (первые 8 символов)
- TextField для ввода ключа
- Кнопка включить/выключить
- Настройка автоблокировки (минуты)
- Лог передачи ключей

### 12. CallScreen
- Полноэкранный экран
- Аватар и имя собеседника
- Таймер длительности (Timer.periodic)
- Кнопки: микрофон, камера (video), завершить

## Структура проекта
lib/
├── data/
│   ├── api/          # Dio клиент + endpoints
│   ├── model/        # JSON модели (json_serializable)
│   ├── repository/   # Реализации репозиториев
│   └── local/        # SecureStorage + SharedPreferences
├── domain/
│   ├── model/        # Domain модели
│   ├── repository/   # Интерфейсы
│   └── usecase/      # Use cases
├── presentation/
│   ├── screens/      # Экраны (StatelessWidget/BlocBuilder)
│   ├── widgets/      # Переиспользуемые виджеты
│   ├── bloc/         # BLoC классы (events, states, bloc)
│   └── router/       # go_router конфигурация
└── di/               # get_it + injectable модули

## pubspec.yaml зависимости (основные)
dependencies:
  flutter_bloc: ^8.1.5
  go_router: ^14.0.0
  dio: ^5.4.3
  web_socket_channel: ^3.0.0
  get_it: ^7.7.0
  injectable: ^2.4.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.2
  cached_network_image: ^3.3.1
  image_picker: ^1.1.2
  file_picker: ^8.1.2
  json_annotation: ^4.9.0
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.11
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.1

## Требования
1. Создай все файлы сразу — не пропускай ни один экран
2. Каждый экран подключён к API и BLoC
3. Ошибки сети → ScaffoldMessenger.of(context).showSnackBar(...)
4. Загрузка → CircularProgressIndicator
5. JWT автоматически в Dio Interceptor (с refresh логикой)
6. WebSocket: переподключение при разрыве (exponential backoff)
7. Тёмная тема через ThemeMode.system
8. Все тексты на русском языке
9. Минимальный SDK Flutter: 3.22, Dart: 3.4
10. Android minSdkVersion: 26, iOS deployment target: 13.0
11. Используй json_serializable + build_runner для моделей
12. Не задавай вопросов — сразу пиши весь код