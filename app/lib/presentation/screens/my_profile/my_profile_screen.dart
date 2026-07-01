import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../domain/repositories/attachments_repository.dart';
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
  int? _lastFilledUserId;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final bloc = context.read<MyProfileBloc>();

    // Show loading
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.loading),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload via attachments
      final attachmentsRepo = GetIt.I<AttachmentsRepository>();
      final attachment = await attachmentsRepo.upload(
        bytes: bytes,
        fileName: fileName,
      );

      // Update profile with avatar URL
      final avatarUrl = attachment.url;
      bloc.add(ProfileUpdateMe(avatarUrl: avatarUrl));

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.avatarUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLoading}: $e')),
        );
      }
    }
  }

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<MyProfileBloc>();
    final state = bloc.state;
    if (state is! ProfileReady) return;
    _username.text = state.user.username;
    _email.text = state.user.email ?? '';
    _bio.text = state.user.bio ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.editProfile),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bio,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.profile,
                  prefixIcon: const Icon(Icons.info_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final username = _username.text.trim();
    final email = _email.text.trim();
    final bio = _bio.text.trim();
    // Dispatch event — result is shown by BlocConsumer listener
    bloc.add(ProfileUpdateMe(
      username: username.isNotEmpty ? username : null,
      email: email.isNotEmpty ? email : null,
      bio: bio.isNotEmpty ? bio : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.myProfile,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 22),
            onPressed: () => _edit(context),
          ),
        ],
      ),
      body: BlocConsumer<MyProfileBloc, ProfileState>(
        listenWhen: (a, b) => b is ProfileReady,
        listener: (context, state) {
          if (state is ProfileReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          } else if (state is ProfileReady && state.error == null) {
            // Show success only when we transitioned from a previous state
            // (not on initial load)
            final prev = context.read<MyProfileBloc>().state;
            if (prev is ProfileReady && prev.user != state.user) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context).profileUpdated),
                    backgroundColor: Colors.green,
                  ),
                );
            }
          }
        },
        builder: (context, state) {
          if (state is ProfileInitial || state is ProfileLoading) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }
          final ready = state as ProfileReady;
          if (_lastFilledUserId != ready.user.id) {
            _username.text = ready.user.username;
            _email.text = ready.user.email ?? '';
            _bio.text = ready.user.bio ?? '';
            _lastFilledUserId = ready.user.id;
          }
          final user = ready.user;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar with upload
              Center(
                child: GestureDetector(
                  onTap: () => _pickAndUploadAvatar(context),
                  child: Stack(
                    children: [
                      // Avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: user.avatarUrl != null &&
                                user.avatarUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: CachedNetworkImage(
                                  imageUrl: user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: scheme.primaryContainer,
                                    child: Center(
                                      child: Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: scheme.primaryContainer,
                                    child: Center(
                                      child: Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary,
                                      scheme.primary.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Center(
                                  child: Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      // Upload overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: scheme.onPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Username
              Center(
                child: Text(
                  user.username,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info cards
              _InfoCard(
                icon: Icons.alternate_email_rounded,
                label: l10n.email,
                value: user.email ?? l10n.notSpecified,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.phone_rounded,
                label: l10n.phone,
                value: user.phoneNumber ?? l10n.notSpecified,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.info_outline_rounded,
                label: l10n.profile,
                value: user.bio ?? l10n.notSpecified,
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.access_time_rounded,
                label: l10n.wasOnline,
                value: user.lastSeen?.toLocal().toString() ?? '—',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
