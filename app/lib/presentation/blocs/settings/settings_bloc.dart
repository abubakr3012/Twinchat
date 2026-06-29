import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/repositories/settings_repository.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => const [];
}

class SettingsLoad extends SettingsEvent {
  const SettingsLoad();
}

class SettingsUpdateChat extends SettingsEvent {
  const SettingsUpdateChat(this.settings);
  final ChatSettings settings;
  @override
  List<Object?> get props => [settings];
}

class SettingsUpdatePrivacy extends SettingsEvent {
  const SettingsUpdatePrivacy(this.settings);
  final PrivacySettings settings;
  @override
  List<Object?> get props => [settings];
}

class SettingsUpdateLanguage extends SettingsEvent {
  const SettingsUpdateLanguage(this.settings);
  final LanguageSettings settings;
  @override
  List<Object?> get props => [settings];
}

sealed class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => const [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsReady extends SettingsState {
  const SettingsReady({
    required this.chat,
    required this.privacy,
    required this.language,
    this.error,
  });
  final ChatSettings chat;
  final PrivacySettings privacy;
  final LanguageSettings language;
  final String? error;

  SettingsReady copyWith({
    ChatSettings? chat,
    PrivacySettings? privacy,
    LanguageSettings? language,
    String? error,
    bool clearError = false,
  }) =>
      SettingsReady(
        chat: chat ?? this.chat,
        privacy: privacy ?? this.privacy,
        language: language ?? this.language,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [chat, privacy, language, error];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepository repository})
      : _repo = repository,
        super(const SettingsInitial()) {
    on<SettingsLoad>(_onLoad);
    on<SettingsUpdateChat>(_onUpdateChat);
    on<SettingsUpdatePrivacy>(_onUpdatePrivacy);
    on<SettingsUpdateLanguage>(_onUpdateLanguage);
  }

  final SettingsRepository _repo;

  Future<void> _onLoad(_, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      final chat = await _repo.getChat();
      final privacy = await _repo.getPrivacy();
      final language = await _repo.getLanguage();
      emit(SettingsReady(chat: chat, privacy: privacy, language: language));
    } on Object catch (e) {
      emit(SettingsReady(
        chat: const ChatSettings(theme: 'system', textSize: 14, notifications: true),
        privacy: const PrivacySettings(
          seePhoneNumber: 'contacts',
          seeProfilePhoto: 'contacts',
          seeLastSeen: 'contacts',
          autoDeleteMessages: false,
          messageTtlDays: 30,
          twoFactorAuth: false,
        ),
        language: const LanguageSettings(language: 'ru', autoTranslate: false),
        error: extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onUpdateChat(
    SettingsUpdateChat event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsReady) return;
    try {
      final updated = await _repo.updateChat(event.settings);
      emit((state as SettingsReady).copyWith(chat: updated, clearError: true));
    } on Object catch (e) {
      emit((state as SettingsReady).copyWith(error: extractErrorMessage(e)));
    }
  }

  Future<void> _onUpdatePrivacy(
    SettingsUpdatePrivacy event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsReady) return;
    try {
      final updated = await _repo.updatePrivacy(event.settings);
      emit((state as SettingsReady).copyWith(privacy: updated, clearError: true));
    } on Object catch (e) {
      emit((state as SettingsReady).copyWith(error: extractErrorMessage(e)));
    }
  }

  Future<void> _onUpdateLanguage(
    SettingsUpdateLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is! SettingsReady) return;
    try {
      final updated = await _repo.updateLanguage(event.settings);
      emit((state as SettingsReady).copyWith(language: updated, clearError: true));
    } on Object catch (e) {
      emit((state as SettingsReady).copyWith(error: extractErrorMessage(e)));
    }
  }
}