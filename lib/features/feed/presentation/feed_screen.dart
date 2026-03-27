import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/feed_provider.dart';
import '../widgets/create_post_dialog.dart';

//
// ✅ TOP-LEVEL FUNCTION (FIXED POSITION)
//
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
          final comments = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Comments",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),

              ...comments.map((c) => ListTile(
                title: Text(c['users']?['name'] ?? '',
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(c['content'],
                    style: const TextStyle(color: Colors.white70)),
              )),
            ],
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

                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 400 + index * 100),
                    tween: Tween(begin: 30.0, end: 0.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, value),
                        child: Opacity(
                          opacity: 1 - (value / 30),
                          child: child,
                        ),
                      );
                    },
                    child: _PostCard(post: post, ref: ref),
                  );
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
        elevation: 8,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: post.avatarUrl != null
                          ? NetworkImage(post.avatarUrl!)
                          : null,
                      child: post.avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTime(post.createdAt),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  post.type.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),

                // 🔥 ADD THIS BLOCK
                if (post.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(post.imageUrl!),
                    ),
                  ),

                const SizedBox(height: 12),

                FutureBuilder(
                  future: Future.wait([
                    ref.read(feedRepositoryProvider).getLikeCount(post.id),
                    ref.read(feedRepositoryProvider).getCommentCount(post.id),
                  ]),
                  builder: (context, snapshot) {
                    final likes = snapshot.data?[0] ?? 0;
                    final comments = snapshot.data?[1] ?? 0;

                    return Row(
                      children: [
                        _iconButton(
                          icon: Icons.favorite_border,
                          color: Colors.pinkAccent,
                          count: likes,
                          onTap: () async {
                            await ref
                                .read(feedRepositoryProvider)
                                .toggleLike(post.id);
                            ref.invalidate(feedProvider);
                          },
                        ),

                        const SizedBox(width: 20),

                        _iconButton(
                          icon: Icons.chat_bubble_outline,
                          color: Colors.greenAccent,
                          count: comments,
                          onTap: () {
                            showCommentsBottomSheet(context, post.id, ref);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 5),
        Text("$count", style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

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
    controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.blue.withValues(alpha: 0.2 * controller.value),
                Colors.purple.withValues(alpha: 0.2),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: ParticlePainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;

  ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < 10; i++) {
      paint.color = (i % 2 == 0
          ? Colors.cyanAccent
          : Colors.purpleAccent)
          .withValues(alpha: 0.12);

      final x = (i * 100.0 + progress * 40) % size.width;
      final y = (i * 140.0 + progress * 50) % size.height;

      canvas.drawCircle(Offset(x, y), 4, paint);

      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(x, y), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

String _formatTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
  if (diff.inHours < 24) return "${diff.inHours}h ago";
  return "${diff.inDays}d ago";
}