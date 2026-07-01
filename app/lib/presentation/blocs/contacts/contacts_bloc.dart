import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api/api_helpers.dart';
import '../../../domain/entities/contact.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/contacts_repository.dart';
import '../../../domain/repositories/users_repository.dart';

sealed class ContactsEvent extends Equatable {
  const ContactsEvent();
  @override
  List<Object?> get props => const [];
}

class ContactsLoad extends ContactsEvent {
  const ContactsLoad();
}

class ContactsSearch extends ContactsEvent {
  const ContactsSearch(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class ContactsAdd extends ContactsEvent {
  const ContactsAdd({required this.user, this.nickname});
  final User user;
  final String? nickname;
  @override
  List<Object?> get props => [user, nickname];
}

class ContactsDelete extends ContactsEvent {
  const ContactsDelete(this.contactId);
  final int contactId;
  @override
  List<Object?> get props => [contactId];
}

class ContactsBlock extends ContactsEvent {
  const ContactsBlock(this.contactId);
  final int contactId;
  @override
  List<Object?> get props => [contactId];
}

class ContactsSyncDeviceContact extends ContactsEvent {
  const ContactsSyncDeviceContact({required this.name, required this.phone});
  final String name;
  final String phone;
  @override
  List<Object?> get props => [name, phone];
}

sealed class ContactsState extends Equatable {
  const ContactsState();
  @override
  List<Object?> get props => const [];
}

class ContactsInitial extends ContactsState {
  const ContactsInitial();
}

class ContactsLoading extends ContactsState {
  const ContactsLoading();
}

class ContactsReady extends ContactsState {
  const ContactsReady({
    required this.contacts,
    this.searchResults = const <User>[],
    this.searchQuery = '',
    this.error,
  });

  final List<Contact> contacts;
  final List<User> searchResults;
  final String searchQuery;
  final String? error;

  ContactsReady copyWith({
    List<Contact>? contacts,
    List<User>? searchResults,
    String? searchQuery,
    String? error,
    bool clearError = false,
  }) =>
      ContactsReady(
        contacts: contacts ?? this.contacts,
        searchResults: searchResults ?? this.searchResults,
        searchQuery: searchQuery ?? this.searchQuery,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [contacts, searchResults, searchQuery, error];
}

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  ContactsBloc({
    required ContactsRepository contactsRepository,
    required UsersRepository usersRepository,
  })  : _contacts = contactsRepository,
        _users = usersRepository,
        super(const ContactsInitial()) {
    on<ContactsLoad>(_onLoad);
    on<ContactsSearch>(_onSearch);
    on<ContactsAdd>(_onAdd);
    on<ContactsDelete>(_onDelete);
    on<ContactsBlock>(_onBlock);
    on<ContactsSyncDeviceContact>(_onSyncDeviceContact);
  }

  final ContactsRepository _contacts;
  final UsersRepository _users;

  Future<void> _onLoad(_, Emitter<ContactsState> emit) async {
    emit(const ContactsLoading());
    try {
      final list = await _contacts.list();
      emit(ContactsReady(contacts: list));
    } on Object catch (e) {
      emit(ContactsReady(
        contacts: const [],
        error: extractErrorMessage(e),
      ));
    }
  }

  Future<void> _onSearch(
    ContactsSearch event,
    Emitter<ContactsState> emit,
  ) async {
    final prev = state;
    if (prev is! ContactsReady) return;
    emit(prev.copyWith(searchQuery: event.query, searchResults: const []));
    final q = event.query.trim();
    if (q.isEmpty) return;
    try {
      final results = await _users.search(q);
      if (state is ContactsReady) {
        emit((state as ContactsReady).copyWith(searchResults: results));
      }
    } on Object catch (e) {
      if (state is ContactsReady) {
        emit((state as ContactsReady)
            .copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  Future<void> _onAdd(ContactsAdd event, Emitter<ContactsState> emit) async {
    if (state is! ContactsReady) return;
    try {
      await _contacts.add(
        contactId: event.user.id,
        nickname: event.nickname,
      );
      final list = await _contacts.list();
      if (state is ContactsReady) {
        emit((state as ContactsReady).copyWith(
          contacts: list,
          searchResults: const [],
          clearError: true,
        ));
      }
    } on Object catch (e) {
      if (state is ContactsReady) {
        emit((state as ContactsReady)
            .copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  Future<void> _onDelete(
    ContactsDelete event,
    Emitter<ContactsState> emit,
  ) async {
    if (state is! ContactsReady) return;
    try {
      await _contacts.delete(event.contactId);
      final list = await _contacts.list();
      if (state is ContactsReady) {
        emit((state as ContactsReady).copyWith(contacts: list));
      }
    } on Object catch (e) {
      if (state is ContactsReady) {
        emit((state as ContactsReady)
            .copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  Future<void> _onBlock(
    ContactsBlock event,
    Emitter<ContactsState> emit,
  ) async {
    if (state is! ContactsReady) return;
    try {
      await _contacts.block(event.contactId);
      final list = await _contacts.list();
      if (state is ContactsReady) {
        emit((state as ContactsReady).copyWith(contacts: list));
      }
    } on Object catch (e) {
      if (state is ContactsReady) {
        emit((state as ContactsReady)
            .copyWith(error: extractErrorMessage(e)));
      }
    }
  }

  Future<void> _onSyncDeviceContact(
    ContactsSyncDeviceContact event,
    Emitter<ContactsState> emit,
  ) async {
    try {
      // Search for user by phone number
      final users = await _users.search(event.phone);
      if (users.isNotEmpty) {
        // If user found, add to contacts
        await _contacts.add(
          contactId: users.first.id,
          nickname: event.name,
        );
      }
    } catch (e) {
      // Silently fail for individual contact sync errors
      // to avoid spamming user with error messages
    }
  }
}