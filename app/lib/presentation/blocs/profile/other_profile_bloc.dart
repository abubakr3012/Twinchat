import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/users_repository.dart';

sealed class OtherProfileEvent extends Equatable {
  const OtherProfileEvent();
  @override
  List<Object?> get props => const [];
}

class OtherProfileLoad extends OtherProfileEvent {
  const OtherProfileLoad(this.userId);
  final int userId;
  @override
  List<Object?> get props => [userId];
}

sealed class OtherProfileState extends Equatable {
  const OtherProfileState();
  @override
  List<Object?> get props => const [];
}

class OtherProfileLoading extends OtherProfileState {
  const OtherProfileLoading();
}

class OtherProfileReady extends OtherProfileState {
  const OtherProfileReady(this.user, {this.error});
  final User user;
  final String? error;

  OtherProfileReady copyWith({User? user, String? error, bool clearError = false}) {
    final nextError = clearError ? null : (error ?? this.error);
    return OtherProfileReady(
      user ?? this.user,
      error: nextError,
    );
  }

  @override
  List<Object?> get props => [user, error];
}

class OtherProfileBloc extends Bloc<OtherProfileEvent, OtherProfileState> {
  OtherProfileBloc({required UsersRepository repository})
      : _repo = repository,
        super(const OtherProfileLoading()) {
    on<OtherProfileLoad>(_onLoad);
  }

  final UsersRepository _repo;

  Future<void> _onLoad(OtherProfileLoad e, Emitter<OtherProfileState> emit) async {
    emit(const OtherProfileLoading());
    try {
      final u = await _repo.getById(e.userId);
      emit(OtherProfileReady(u));
    } on Object catch (err) {
      emit(OtherProfileReady(
        const User(id: 0, username: ''),
        error: extractErrorMessage(err),
      ));
    }
  }
}