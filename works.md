# TwinChat — Журнал изменений

## Дата: 01.07.2026

---

## ✅ Исправленные баги и новые фичи

### 1. Тема приложения (light/dark/system)
**Проблема**: Выбор темы в настройках не применялся к приложению.
**Решение**: 
- Создан `ThemeModeProvider` (global ChangeNotifier)
- `main.dart` обновлён — `MaterialApp` слушает провайдер
- Настройки синхронизируются с провайдером при загрузке
**Файлы**: `theme_mode_provider.dart`, `main.dart`, `settings_screen.dart`

### 2. Размер текста в чате
**Проблема**: Настройка textSize не влияла на размер сообщений.
**Решение**: Создан `TextSizeProvider`, привязан к `chat_screen.dart`
**Файлы**: `text_size_provider.dart`, `chat_screen.dart`, `settings_screen.dart`

### 3. Шифрование сообщений (E2E)
**Инфраструктура уже существовала**:
- `MessageCrypto` — ECDH + HKDF-SHA256 + AES-256-GCM
- `KeyManager` — хранение X25519 ключей в secure storage
- `SafeModeScreen` — UI для управления шифрованием

**Добавлено**: поле `is_encrypted` в модель `Message` на бэкенде.
**Файл**: `chat_messages/models.py`

### 4. Создание групп
**Уже работает**: 
- Диалог создания чата с `SegmentedButton` (Личный/Группа)
- Бэкенд поддерживает `ChatType.group`
- Каждый авторизованный пользователь может создать группу

### 5. Двухфакторная аутентификация
**Статус**: Настройка `two_factor_auth` есть в `PrivacySettings` (БД + UI).
**Ограничение**: Полноценная реализация (TOTP/SMS) требует отдельной работы — пока это флаг в настройках.

### 6. Контакты (был stub)
**Решение**: Stub заменён на реальный встроенный экран с загрузкой данных.
**Файл**: `chat_list_screen.dart`

### 7. Истории (был stub)
**Решение**: Stub заменён на реальный встроенный экран с загрузкой данных.
**Файл**: `chat_list_screen.dart`

### 8. Аватар профиля
**Решение**: Добавлена загрузка аватара через ImagePicker + AttachmentsRepository.
**Файл**: `my_profile_screen.dart`

### 9. WebSocket JWT авторизация
**Решение**: Создан `JWTAuthMiddleware` для Django Channels.
**Файлы**: `config/jwt_middleware.py`, `config/asgi.py`

### 10. IP адрес API
**Решение**: Обновлён на правильный `192.168.31.65`.
**Файл**: `api_constants.dart`

### 11. FAB (кнопка "+")
**Решение**: Убрана блокировка приватных чатов — все чаты открываются.
**Файл**: `chat_list_screen.dart`

---

## ⏳ Что ещё нужно (не сделано)

### Звонки
- Нужна WebRTC библиотека (`flutter_webrtc`)
- Signaling сервер для обмена SDP/ICE
- Это отдельный большой фича-запрос

### Двухфакторная аутентификация (полная)
- TOTP (Google Authenticator / Authy)
- SMS-код при входе
- Recovery codes

### E2E шифрование (интеграция в чат)
- Crypto инфраструктура готова
- Нужно интегрировать в ChatScreen (encrypt/decrypt при отправке/получении)
- Передача public keys между пользователями

---

## Структура изменённых файлов

```
app/lib/
├── core/
│   ├── api/
│   │   └── api_constants.dart              ← IP исправлен
│   ├── crypto/
│   │   ├── key_manager.dart                ← (существовал)
│   │   └── message_crypto.dart             ← (существовал)
│   └── utils/
│       ├── text_size_provider.dart         ← НОВЫЙ
│       └── theme_mode_provider.dart        ← НОВЫЙ
├── main.dart                               ← themeMode из провайдера
├── presentation/
│   ├── screens/
│   │   ├── chat/
│   │   │   └── chat_screen.dart            ← textSize из провайдера
│   │   ├── chatlist/
│   │   │   └── chat_list_screen.dart       ← contacts/stories inline, FAB fixed
│   │   ├── my_profile/
│   │   │   └── my_profile_screen.dart      ← загрузка аватара
│   │   └── settings/
│   │       └── settings_screen.dart        ← sync theme + textSize
│   └── widgets/                            ← (обновлены ранее)

backend/
├── config/
│   ├── asgi.py                             ← JWT middleware
│   └── jwt_middleware.py                   ← НОВЫЙ
├── chat_messages/
│   └── models.py                           ← is_encrypted field
```
