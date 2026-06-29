import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/repositories/users_repository.dart';
import '../../blocs/profile/other_profile_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OtherProfileBloc>(
      create: (_) => OtherProfileBloc(repository: GetIt.I<UsersRepository>())
        ..add(OtherProfileLoad(userId)),
      child: _ProfileView(userId: userId),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/contacts'),
        ),
      ),
      body: BlocConsumer<OtherProfileBloc, OtherProfileState>(
        listenWhen: (a, b) =>
            b is OtherProfileReady && b.user.id == 0 && b.error != null,
        listener: (context, state) {
          if (state is OtherProfileReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is OtherProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = (state as OtherProfileReady).user;
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
                leading: const Icon(Icons.info_outline),
                title: const Text('О себе'),
                subtitle: Text(user.bio ?? '—'),
              ),
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
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Написать'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Прямой чат появится в следующей версии',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('Позвонить'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Выберите чат для звонка'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}