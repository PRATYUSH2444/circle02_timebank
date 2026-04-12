import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/models/post_model.dart';
import '../../../utils/time_utils.dart';
import '../providers/feed_provider.dart';
import '../repository/feed_repository.dart';
import '../widgets/create_post_dialog.dart';

// ─── Comments bottom sheet ────────────────────────────────────────────────────

void showCommentsBottomSheet(BuildContext context, String postId, WidgetRef ref) {
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<List> loadComments() async =>
              await ref.read(feedRepositoryProvider).fetchComments(postId);

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text("Comments",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FutureBuilder(
                  future: loadComments(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final comments = snapshot.data as List;
                    return SizedBox(
                      height: 280,
                      child: comments.isEmpty
                          ? const Center(
                          child: Text("No comments yet 💬",
                              style: TextStyle(color: Colors.white38)))
                          : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: Colors.white10, height: 1),
                        itemBuilder: (_, i) {
                          final c = comments[i];
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                  Colors.cyan.withOpacity(0.2),
                                  child: Text(
                                    (c['users']?['name'] ?? 'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.cyan,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['users']?['name'] ?? 'User',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(c['content'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // input
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border:
                    Border(top: BorderSide(color: Colors.white10, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Write a comment...",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF1C1C1C),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          if (controller.text.trim().isEmpty) return;
                          await ref.read(feedRepositoryProvider).addComment(
                            postId: postId,
                            content: controller.text.trim(),
                            ref: ref,
                          );
                          controller.clear();
                          setState(() {});
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                              color: Colors.cyan, shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded,
                              color: Colors.black, size: 18),
                        ),
                      ),
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

// ─── Feed screen ──────────────────────────────────────────────────────────────

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text(
          "Feed",
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const CreatePostDialog(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.cyan,
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: () async => ref.invalidate(feedProvider),
        child: postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.dynamic_feed_outlined,
                        color: Colors.white24, size: 52),
                    SizedBox(height: 14),
                    Text("No posts yet\nBe the first to post! 🚀",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, height: 1.6)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: posts.length,
              itemBuilder: (context, index) => _PostCard(post: posts[index]),
            );
          },
          loading: () => ListView.builder(
            itemCount: 4,
            itemBuilder: (_, __) => const _SkeletonCard(),
          ),
          error: (e, _) => Center(
            child: Text("Error: $e",
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "feed_fab",
        backgroundColor: Colors.cyan,
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const CreatePostDialog(),
        ),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A), shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 120, height: 12,
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(width: 70, height: 10,
                    decoration: BoxDecoration(color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6))),
              ]),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 12, decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 8),
          Container(width: 200, height: 12, decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(6))),
        ],
      ),
    );
  }
}

// ─── Post card ────────────────────────────────────────────────────────────────

class _PostCard extends ConsumerWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(feedRepositoryProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: post.avatarUrl != null
                      ? CachedNetworkImageProvider(post.avatarUrl!)
                      : null,
                  backgroundColor: Colors.cyan.withOpacity(0.15),
                  child: post.avatarUrl == null
                      ? Text(post.userName[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.cyan, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.userName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      // ✅ FIXED: TimeUtils.timeAgo → correct IST relative time
                      Text(TimeUtils.timeAgo(post.createdAt),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(post.content,
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, height: 1.5)),
          ),

          // ── Image ───────────────────────────────────────────────────────
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: const Color(0xFF1E1E1E),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    color: const Color(0xFF1E1E1E),
                    child: const Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
              ),
            ),

          // ── Actions ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () async => await repo.toggleLike(post.id, ref),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: post.isLiked
                          ? Colors.red.withOpacity(0.15)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : Colors.white54,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text("${post.likeCount}",
                            style: TextStyle(
                                color: post.isLiked
                                    ? Colors.red
                                    : Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Comment
                GestureDetector(
                  onTap: () => showCommentsBottomSheet(context, post.id, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Colors.white54, size: 18),
                        const SizedBox(width: 6),
                        Text("${post.commentCount}",
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({super.key});
  @override
  Widget build(BuildContext context) => Container(color: Colors.black);
}

class NeonParticles extends StatelessWidget {
  const NeonParticles({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}