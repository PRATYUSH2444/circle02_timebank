import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../providers/session_provider.dart';
import '../repository/session_repository.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  String formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return "Invalid time";
    return "${dt.day}/${dt.month} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  bool isExpired(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    return DateTime.now().isAfter(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionProvider);

    /// 🔥 SAFE AUTO EXPIRY
    Future.microtask(() {
      ref.read(sessionRepositoryProvider).autoExpireSessions();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Sessions"),
        backgroundColor: Colors.transparent,
      ),

      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text("No sessions yet",
                  style: TextStyle(color: Colors.white70)),
            );
          }

          final upcoming =
          sessions.where((s) => s['status'] == 'booked').toList();

          final completed =
          sessions.where((s) => s['status'] == 'completed').toList();

          final cancelled =
          sessions.where((s) => s['status'] == 'cancelled').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              if (upcoming.isNotEmpty) ...[
                const _SectionTitle("🟢 Upcoming"),
                ...upcoming.map((s) => _SessionCard(s: s)),
              ],

              if (completed.isNotEmpty) ...[
                const _SectionTitle("✅ Completed"),
                ...completed.map((s) => _SessionCard(s: s)),
              ],

              if (cancelled.isNotEmpty) ...[
                const _SectionTitle("❌ Cancelled"),
                ...cancelled.map((s) => _SessionCard(s: s)),
              ],
            ],
          );
        },

        loading: () =>
        const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

/// ================= TITLE =================
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// ================= CARD =================
class _SessionCard extends ConsumerStatefulWidget {
  final dynamic s;
  const _SessionCard({required this.s});

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
  bool loading = false;

  Future<void> openMeeting(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri,
        mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open meeting")),
      );
    }
  }

  String formatTime(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return "Invalid time";
    return "${dt.day}/${dt.month} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  bool isExpired(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return false;
    return DateTime.now().isAfter(dt);
  }

  @override
  Widget build(BuildContext context) {
    final repo = SessionRepository();
    final s = widget.s;

    final currentUser =
        Supabase.instance.client.auth.currentUser!.id;

    final isTeacher = s['teacher_id'] == currentUser;
    final userData =
    isTeacher ? s['student_data'] : s['teacher_data'];

    final String name = userData?['name'] ?? "User";
    final String? avatar = userData?['avatar_url'];

    final String status = s['status'] ?? 'unknown';
    final String slotTime = s['slot_time'].toString();
    final bool expired = isExpired(slotTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF111111)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                avatar != null ? NetworkImage(avatar) : null,
                child:
                avatar == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTeacher
                          ? "Student: $name"
                          : "Teacher: $name",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s['skill'] ?? "Session",
                      style:
                      const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),

              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status == 'completed'
                      ? Colors.green
                      : status == 'cancelled'
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// TIME
          Text(
            "🕒 ${formatTime(slotTime)}",
            style: const TextStyle(color: Colors.white70),
          ),

          if (expired && status == 'booked')
            const Text(
              "⚠️ Session expired",
              style: TextStyle(color: Colors.redAccent),
            ),

          const SizedBox(height: 12),

          /// ACTIONS
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [

              /// JOIN
              if (s['meeting_url'] != null &&
                  status == 'booked')
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_call),
                  label: const Text("Join"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                  onPressed: () =>
                      openMeeting(s['meeting_url'].toString()),
                ),

              /// CHAT (FIXED)
              if (status == 'booked')
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat"),
                  onPressed: () {
                    context.push('/chat/${s['id']}');                  },
                ),

              /// COMPLETE
              if (isTeacher && status == 'booked')
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: loading
                      ? const Text("Processing...")
                      : const Text("Complete"),
                  onPressed: loading
                      ? null
                      : () async {
                    setState(() => loading = true);

                    await repo.completeSession(s['id']);
                    ref.invalidate(sessionProvider);

                    setState(() => loading = false);

                    if (!mounted) return;

                    _showRatingDialog(context, s['id']);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                          content:
                          Text("Session completed")),
                    );
                  },
                ),

              /// CANCEL
              if (status == 'booked')
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                    setState(() => loading = true);

                    await repo.cancelSession(s['id']);
                    ref.invalidate(sessionProvider);

                    setState(() => loading = false);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(
      BuildContext context, String sessionId) {
    int rating = 5;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Rate Session",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return Slider(
                    value: rating.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: "$rating",
                    onChanged: (val) {
                      setState(() => rating = val.toInt());
                    },
                  );
                },
              ),
              TextField(
                controller: controller,
                style:
                const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Review",
                  hintStyle:
                  TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await SessionRepository().rateSession(
                  sessionId,
                  rating,
                  controller.text,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}