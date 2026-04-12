import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/models/post_model.dart';
import '../providers/feed_provider.dart';
import '../repository/feed_repository.dart';
import '../widgets/create_post_dialog.dart';

/// ================= COMMENTS =================
void showCommentsBottomSheet(
    BuildContext context, String postId, WidgetRef ref) {
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black,
    isScrollControlled: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<List> loadComments() async {
            return await ref
                .read(feedRepositoryProvider)
                .fetchComments(postId);
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// COMMENTS LIST
                FutureBuilder(
                  future: loadComments(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final comments = snapshot.data as List;

                    return SizedBox(
                      height: 300,
                      child: comments.isEmpty
                          ? const Center(
                        child: Text(
                          "No comments yet",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                          : ListView(
                        children: comments.map((c) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (c['users']?['name'] ?? 'U')[0],
                              ),
                            ),
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
                      ),
                    );
                  },
                ),

                /// INPUT
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Write a comment...",
                            hintStyle:
                            TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.cyan),
                        onPressed: () async {
                          if (controller.text.trim().isEmpty) return;

                          await ref
                              .read(feedRepositoryProvider)
                              .addComment(
                            postId: postId,
                            content: controller.text.trim(),
                            ref: ref,
                          );

                          controller.clear();
                          setState(() {});
                        },
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// ================= FEED =================
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

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedProvider);
        },
        child: Stack(
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
                    return _PostCard(post: posts[index]);
                  },
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              ),
              error: (e, _) =>
                  Center(child: Text("Error: $e")),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: "feed_fab",           // ✅ FIX — unique heroTag
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

/// ================= POST CARD =================
class _PostCard extends ConsumerWidget {
  final PostModel post;

  const _PostCard({required this.post});

  String getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${(diff.inDays / 7).floor()} weeks ago";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(feedRepositoryProvider);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.avatarUrl != null
                      ? CachedNetworkImageProvider(post.avatarUrl!)
                      : null,
                  child: post.avatarUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    post.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  getTimeAgo(post.createdAt),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// CONTENT
            Text(
              post.content,
              style: const TextStyle(color: Colors.white70),
            ),

            /// IMAGE
            if (post.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                    const LinearProgressIndicator(),
                    errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            /// ACTIONS
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await repo.toggleLike(post.id, ref);
                  },
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: post.isLiked
                            ? Colors.red
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text("${post.likeCount}",
                          style:
                          const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                GestureDetector(
                  onTap: () {
                    showCommentsBottomSheet(
                        context, post.id, ref);
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.comment,
                          color: Colors.white),
                      const SizedBox(width: 6),
                      Text("${post.commentCount}",
                          style:
                          const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= BACKGROUND =================
class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black);
  }
}

class NeonParticles extends StatelessWidget {
  const NeonParticles({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}