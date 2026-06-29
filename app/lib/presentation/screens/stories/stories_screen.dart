import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../domain/entities/story.dart';
import '../../../domain/repositories/stories_repository.dart';
import '../../blocs/stories/stories_bloc.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StoriesBloc>(
      create: (_) => StoriesBloc(repository: GetIt.I<StoriesRepository>())
        ..add(const StoriesLoad()),
      child: const _StoriesView(),
    );
  }
}

class _StoriesView extends StatelessWidget {
  const _StoriesView();

  Future<void> _add(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!context.mounted) return;
    final file = File(picked.path);
    final type = picked.mimeType?.startsWith('video') == true ? 'video' : 'image';
    context.read<StoriesBloc>().add(StoriesUpload(
          file: file,
          mediaType: type,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Истории'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: BlocConsumer<StoriesBloc, StoriesState>(
        listenWhen: (a, b) => b is StoriesReady && b.error != null,
        listener: (context, state) {
          if (state is StoriesReady && state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is StoriesInitial || state is StoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final ready = state as StoriesReady;
          if (ready.feed.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => context
                  .read<StoriesBloc>()
                  .add(const StoriesLoad()),
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Историй пока нет. Нажмите + чтобы добавить.')),
                ],
              ),
            );
          }
          return Column(
            children: [
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: ready.feed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = ready.feed[i];
                    return _StoryAvatar(
                      story: s,
                      onTap: () => context
                          .read<StoriesBloc>()
                          .add(StoriesOpen(s)),
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: ready.myStories.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = ready.myStories[i];
                    return ListTile(
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: s.mediaType == StoryMediaType.image
                              ? CachedNetworkImage(
                                  imageUrl: s.mediaUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.image),
                                )
                              : const Icon(Icons.play_circle_outline),
                        ),
                      ),
                      title: Text(s.caption?.isNotEmpty == true
                          ? s.caption!
                          : 'История #${s.id}'),
                      subtitle: Text('Просмотров: ${s.viewsCount}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => context
                            .read<StoriesBloc>()
                            .add(StoriesDelete(s.id)),
                      ),
                      onTap: () =>
                          context.read<StoriesBloc>().add(StoriesOpen(s)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.story, required this.onTap});
  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: CircleAvatar(
                radius: 25,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(story.username.isEmpty
                    ? '?'
                    : story.username.characters.first.toUpperCase()),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryViewerScreen extends StatelessWidget {
  const StoryViewerScreen({super.key, required this.story});
  final Story story;

  @override
  Widget build(BuildContext context) {
    return BlocListener<StoriesBloc, StoriesState>(
      listener: (context, state) {
        if (state is StoriesReady && state.opened == null) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: story.mediaType == StoryMediaType.image
                    ? InteractiveViewer(
                        child: CachedNetworkImage(
                          imageUrl: story.mediaUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, __) =>
                              const CircularProgressIndicator(),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image, color: Colors.white),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: Colors.white, size: 64),
                      ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        context.read<StoriesBloc>().add(const StoriesClose());
                      },
                    ),
                    const Spacer(),
                    Text(story.username,
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(
                      '${story.viewsCount} просмотров',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (story.caption != null && story.caption!.isNotEmpty)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      story.caption!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}