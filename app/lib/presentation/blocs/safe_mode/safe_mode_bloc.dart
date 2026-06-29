import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/encryption.dart';
import '../../../domain/repositories/encryption_repository.dart';

sealed class SafeModeEvent extends Equatable {
  const SafeModeEvent();
  @override
  List<Object?> get props => const [];
}

class SafeModeLoad extends SafeModeEvent {
  const SafeModeLoad();
}

class SafeModeEnable extends SafeModeEvent {
  const SafeModeEnable({required this.encryptedKey, required this.fingerprint});
  final String encryptedKey;
  final String fingerprint;
  @override
  List<Object?> get props => [encryptedKey, fingerprint];
}

class SafeModeDisable extends SafeModeEvent {
  const SafeModeDisable();
}

class SafeModeUpdateUi extends SafeModeEvent {
  const SafeModeUpdateUi({required this.keyEntered, required this.autoLockMinutes});
  final bool keyEntered;
  final int autoLockMinutes;
  @override
  List<Object?> get props => [keyEntered, autoLockMinutes];
}

class SafeModeShareKey extends SafeModeEvent {
  const SafeModeShareKey({required this.userId, required this.method});
  final int userId;
  final String method;
  @override
  List<Object?> get props => [userId, method];
}

class SafeModeRevoke extends SafeModeEvent {
  const SafeModeRevoke(this.shareId);
  final int shareId;
  @override
  List<Object?> get props => [shareId];
}

sealed class SafeModeState extends Equatable {
  const SafeModeState();
  @override
  List<Object?> get props => const [];
}

class SafeModeInitial extends SafeModeState {
  const SafeModeInitial();
}

class SafeModeLoading extends SafeModeState {
  const SafeModeLoading();
}

class SafeModeReady extends SafeModeState {
  const SafeModeReady({
    required this.status,
    required this.ui,
    required this.shares,
    this.error,
  });

  final SafeModeStatus status;
  final SafeModeUIState ui;
  final List<SafeModeKeyShare> shares;
  final String? error;

  SafeModeReady copyWith({
    SafeModeStatus? status,
    SafeModeUIState? ui,
    List<SafeModeKeyShare>? shares,
    String? error,
    bool clearError = false,
  }) =>
      SafeModeReady(
        status: status ?? this.status,
        ui: ui ?? this.ui,
        shares: shares ?? this.shares,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [status, ui, shares, error];
}

class SafeModeBloc extends Bloc<SafeModeEvent, SafeModeState> {
  SafeModeBloc({required EncryptionRepository repository})
      : _repo = repository,
        super(const SafeModeInitial()) {
    on<SafeModeLoad>(_onLoad);
    on<SafeModeEnable>(_onEnable);
    on<SafeModeDisable>(_onDisable);
    on<SafeModeUpdateUi>(_onUpdateUi);
    on<SafeModeShareKey>(_onShare);
    on<SafeModeRevoke>(_onRevoke);
  }

  final EncryptionRepository _repo;

  Future<void> _onLoad(_, Emitter<SafeModeState> emit) async {
    emit(const SafeModeLoading());
    try {
      final s = await _repo.status();
      final ui = await _repo.uiState();
      final shares = await _repo.shares();
      emit(SafeModeReady(status: s, ui: ui, shares: shares));
    } on Object catch (e) {
      emit(SafeModeReady(
        status: const SafeModeStatus(isActive: false),
        ui: const SafeModeUIState(keyEntered: false, autoLockMinutes: 10),
        shares: const [],
        error: extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onEnable(SafeModeEnable e, Emitter<SafeModeState> emit) async {
    if (state is! SafeModeReady) return;
    try {
      final status = await _repo.enable(
        encryptedKey: e.encryptedKey,
        keyFingerprint: e.fingerprint,
      );
      final ui = await _repo.uiState();
      final shares = await _repo.shares();
      emit(SafeModeReady(status: status, ui: ui, shares: shares, error: null));
    } on Object catch (err) {
      emit((state as SafeModeReady).copyWith(error: extractErrorMessage(err)));
    }
  }

  Future<void> _onDisable(_, Emitter<SafeModeState> emit) async {
    if (state is! SafeModeReady) return;
    try {
      await _repo.disable();
      add(const SafeModeLoad());
    } on Object catch (err) {
      emit((state as SafeModeReady).copyWith(error: extractErrorMessage(err)));
    }
  }

  Future<void> _onUpdateUi(SafeModeUpdateUi e, Emitter<SafeModeState> emit) async {
    if (state is! SafeModeReady) return;
    try {
      final ui = await _repo.updateUiState(
        SafeModeUIState(
          keyEntered: e.keyEntered,
          autoLockMinutes: e.autoLockMinutes,
        ),
      );
      emit((state as SafeModeReady).copyWith(ui: ui));
    } on Object catch (err) {
      emit((state as SafeModeReady).copyWith(error: extractErrorMessage(err)));
    }
  }

  Future<void> _onShare(SafeModeShareKey e, Emitter<SafeModeState> emit) async {
    if (state is! SafeModeReady) return;
    try {
      await _repo.share(sharedWithUserId: e.userId, method: e.method);
      final shares = await _repo.shares();
      emit((state as SafeModeReady).copyWith(shares: shares));
    } on Object catch (err) {
      emit((state as SafeModeReady).copyWith(error: extractErrorMessage(err)));
    }
  }

  Future<void> _onRevoke(SafeModeRevoke e, Emitter<SafeModeState> emit) async {
    if (state is! SafeModeReady) return;
    try {
      await _repo.revoke(e.shareId);
      final shares = await _repo.shares();
      emit((state as SafeModeReady).copyWith(shares: shares));
    } on Object catch (err) {
      emit((state as SafeModeReady).copyWith(error: extractErrorMessage(err)));
    }
  }
}