import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/repositories/users_repository.dart';
import '../../blocs/profile/my_profile_bloc.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MyProfileBloc>(
      create: (_) => MyProfileBloc(repository: GetIt.I<UsersRepository>())
        ..add(const ProfileLoadMe()),
      child: const _MyProfileView(),
    );
  }
}

class _MyProfileView extends StatefulWidget {
  const _MyProfileView();

  @override
  State<_MyProfileView> createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<_MyProfileView> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _bio = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<MyProfileBloc>();
    final state = bloc.state;
    if (state is! ProfileReady) return;
    _username.text = state.user.username;
    _email.text = state.user.email ?? '';
    _bio.text = state.user.bio ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Редактировать профиль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _username,
              decoration: const InputDecoration(labelText: 'Логин'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bio,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'О себе'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    bloc.add(ProfileUpdateMe(
      username: _username.text.trim(),
      email: _email.text.trim(),
      bio: _bio.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _edit(context),
          ),
        ],
      ),
      body: BlocConsumer<MyProfileBloc, ProfileState>(
        listenWhen: (a, b) => b is ProfileReady && b.error != null,
        listener: (context, state) {
          if (state is ProfileReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is ProfileInitial || state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ready = state as ProfileReady;
          if (!_filled) {
            _username.text = ready.user.username;
            _email.text = ready.user.email ?? '';
            _bio.text = ready.user.bio ?? '';
            _filled = true;
          }
          final user = ready.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 56,
                  child: Text(
                    user.username.isEmpty
                        ? '?'
                        : user.username.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: const Text('Email'),
                subtitle: Text(user.email ?? '—'),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Телефон'),
                subtitle: Text(user.phoneNumber ?? '—'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('О себе'),
                subtitle: Text(user.bio ?? '—'),
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Был в сети'),
                subtitle: Text(user.lastSeen?.toLocal().toString() ?? '—'),
              ),
            ],
          );
        },
      ),
    );
  }
}