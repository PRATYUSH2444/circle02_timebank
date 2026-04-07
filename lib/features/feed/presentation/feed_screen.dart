import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../widgets/create_post_dialog.dart';

/// 🔥 COMMENTS BOTTOM SHEET (SAFE)
void showCommentsBottomSheet(
    BuildContext context, String postId, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    isScrollControlled: true,
    builder: (_) {
      return FutureBuilder(
        future: ref.read(feedRepositoryProvider).fetchComments(postId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final comments = snapshot.data as List;

          if (comments.isEmpty) {
            return const Center(
              child: Text("No comments",
                  style: TextStyle(color: Colors.white)),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: comments.map((c) {
              return ListTile(
                title: Text(
                  c['users']?['name'] ?? 'User',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  c['content'],
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            }).toList(),
          );
        },
      );
    },
  );
}

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Feed"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.cyanAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CreatePostDialog(),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          const AnimatedGradientBackground(),
          const NeonParticles(),

          postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    "No posts yet",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _PostCard(post: post, ref: ref);
                },
              );
            },
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text(e.toString())),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const CreatePostDialog(),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final dynamic post;
  final WidgetRef ref;

  const _PostCard({required this.post, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.userName ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 6),

            Text(post.content ?? ""),

            const SizedBox(height: 10),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () async {
                    await ref
                        .read(feedRepositoryProvider)
                        .toggleLike(post.id);
                    ref.invalidate(feedProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    showCommentsBottomSheet(context, post.id, ref);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// 🔥 FIXED BACKGROUND (WITH DISPOSE)
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose(); // 🔥 FIX
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black);
  }
}

/// 🔥 FIXED PARTICLES (LIGHT VERSION)
class NeonParticles extends StatefulWidget {
  const NeonParticles({super.key});

  @override
  State<NeonParticles> createState() => _NeonParticlesState();
}

class _NeonParticlesState extends State<NeonParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose(); // 🔥 FIX
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // 🔥 simplified
  }
}