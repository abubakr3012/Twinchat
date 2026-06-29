import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/users_repository.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => const [];
}

class ProfileLoadMe extends ProfileEvent {
  const ProfileLoadMe();
}

class ProfileUpdateMe extends ProfileEvent {
  const ProfileUpdateMe({
    this.username,
    this.email,
    this.bio,
    this.avatarUrl,
  });
  final String? username;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  @override
  List<Object?> get props => [username, email, bio, avatarUrl];
}

sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => const [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileReady extends ProfileState {
  const ProfileReady(this.user, {this.error});
  final User user;
  final String? error;

  ProfileReady copyWith({User? user, String? error, bool clearError = false}) {
    final nextError = clearError ? null : (error ?? this.error);
    return ProfileReady(
      user ?? this.user,
      error: nextError,
    );
  }

  @override
  List<Object?> get props => [user, error];
}

class MyProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  MyProfileBloc({required UsersRepository repository})
      : _repo = repository,
        super(const ProfileInitial()) {
    on<ProfileLoadMe>(_onLoad);
    on<ProfileUpdateMe>(_onUpdate);
  }

  final UsersRepository _repo;

  Future<void> _onLoad(_, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final u = await _repo.me();
      emit(ProfileReady(u));
    } on Object catch (e) {
      emit(ProfileReady(
        const User(id: 0, username: ''),
        error: extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onUpdate(ProfileUpdateMe e, Emitter<ProfileState> emit) async {
    if (state is! ProfileReady) return;
    try {
      final u = await _repo.update(
        username: e.username,
        email: e.email,
        bio: e.bio,
        avatarUrl: e.avatarUrl,
      );
      emit(ProfileReady(u, error: null));
    } on Object catch (err) {
      emit((state as ProfileReady).copyWith(error: extractErrorMessage(err)));
    }
  }
}