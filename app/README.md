# TwinChat — Flutter мессенджер

Мобильное приложение мессенджера на Flutter.

## Технологии

- Dart, Flutter SDK ≥ 3.19
- State: flutter_bloc
- Navigation: go_router
- Network: dio
- WebSocket: web_socket_channel
- DI: get_it + injectable
- Storage: flutter_secure_storage + shared_preferences
- Images: cached_network_image, image_picker
- Models: freezed + json_serializable
- i18n: intl + flutter_localizations (ru_RU)

## Запуск

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # кодогенерация freezed/json/injectable
flutter run
```

## Структура

```
lib/
├── core/              # api, error, storage, theme, utils
├── data/              # datasources, models (DTO), repositories impl
├── domain/            # entities, repository interfaces, usecases
├── di/                # configureDependencies()
└── presentation/
    ├── blocs/
    ├── router/
    ├── screens/
    └── widgets/
```

## Backend

Базовый URL и WebSocket описаны в `lib/core/api/api_constants.dart`.