import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/story.dart';
import '../../../domain/repositories/stories_repository.dart';

sealed class StoriesEvent extends Equatable {
  const StoriesEvent();
  @override
  List<Object?> get props => const [];
}

class StoriesLoad extends StoriesEvent {
  const StoriesLoad();
}

class StoriesUpload extends StoriesEvent {
  const StoriesUpload({
    required this.file,
    required this.mediaType,
    this.caption,
  });
  final File file;
  final String mediaType;
  final String? caption;
  @override
  List<Object?> get props => [file.path, mediaType, caption];
}

class StoriesDelete extends StoriesEvent {
  const StoriesDelete(this.storyId);
  final int storyId;
  @override
  List<Object?> get props => [storyId];
}

class StoriesOpen extends StoriesEvent {
  const StoriesOpen(this.story);
  final Story story;
  @override
  List<Object?> get props => [story];
}

class StoriesClose extends StoriesEvent {
  const StoriesClose();
}

sealed class StoriesState extends Equatable {
  const StoriesState();
  @override
  List<Object?> get props => const [];
}

class StoriesInitial extends StoriesState {
  const StoriesInitial();
}

class StoriesLoading extends StoriesState {
  const StoriesLoading();
}

class StoriesReady extends StoriesState {
  const StoriesReady({
    required this.feed,
    required this.myStories,
    this.opened,
    this.error,
  });

  final List<Story> feed;
  final List<Story> myStories;
  final Story? opened;
  final String? error;

  StoriesReady copyWith({
    List<Story>? feed,
    List<Story>? myStories,
    Story? opened,
    String? error,
    bool clearError = false,
    bool clearOpened = false,
  }) =>
      StoriesReady(
        feed: feed ?? this.feed,
        myStories: myStories ?? this.myStories,
        opened: clearOpened ? null : (opened ?? this.opened),
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [feed, myStories, opened, error];
}

class StoriesBloc extends Bloc<StoriesEvent, StoriesState> {
  StoriesBloc({required StoriesRepository repository})
      : _repo = repository,
        super(const StoriesInitial()) {
    on<StoriesLoad>(_onLoad);
    on<StoriesUpload>(_onUpload);
    on<StoriesDelete>(_onDelete);
    on<StoriesOpen>(_onOpen);
    on<StoriesClose>(_onClose);
  }

  final StoriesRepository _repo;

  Future<void> _onLoad(_, Emitter<StoriesState> emit) async {
    emit(const StoriesLoading());
    try {
      final feed = await _repo.feed();
      final mine = await _repo.myStories();
      emit(StoriesReady(feed: feed, myStories: mine));
    } on Object catch (e) {
      emit(StoriesReady(
        feed: const [],
        myStories: const [],
        error: extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onUpload(StoriesUpload e, Emitter<StoriesState> emit) async {
    try {
      await _repo.upload(file: e.file, mediaType: e.mediaType, caption: e.caption);
      add(const StoriesLoad());
    } on Object catch (err) {
      if (state is StoriesReady) {
        emit((state as StoriesReady).copyWith(error: extractErrorMessage(err)));
      }
    }
  }

  Future<void> _onDelete(StoriesDelete e, Emitter<StoriesState> emit) async {
    try {
      await _repo.delete(e.storyId);
      add(const StoriesLoad());
    } on Object catch (err) {
      if (state is StoriesReady) {
        emit((state as StoriesReady).copyWith(error: extractErrorMessage(err)));
      }
    }
  }

  void _onOpen(StoriesOpen e, Emitter<StoriesState> emit) {
    if (state is StoriesReady) {
      emit((state as StoriesReady).copyWith(opened: e.story));
    }
  }

  void _onClose(StoriesClose _, Emitter<StoriesState> emit) {
    if (state is StoriesReady) {
      emit((state as StoriesReady).copyWith(clearOpened: true));
    }
  }
}