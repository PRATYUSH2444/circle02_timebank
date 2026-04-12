import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../providers/session_provider.dart';
import '../repository/session_repository.dart';
import '../../../utils/time_utils.dart';

// ─── Sessions screen ──────────────────────────────────────────────────────────

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionProvider);

    Future.microtask(() {
      ref.read(sessionRepositoryProvider).autoExpireSessions();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: const Text("Sessions",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
      ),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.calendar_today_outlined,
                      color: Colors.white24, size: 52),
                  SizedBox(height: 14),
                  Text("No sessions yet\nBook a session to get started 🚀",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, height: 1.6)),
                ],
              ),
            );
          }

          final upcoming =
          sessions.where((s) => s['status'] == 'booked').toList();
          final completed =
          sessions.where((s) => s['status'] == 'completed').toList();
          final cancelled =
          sessions.where((s) => s['status'] == 'cancelled').toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                    icon: Icons.circle, iconColor: Colors.greenAccent,
                    label: "Upcoming", count: upcoming.length),
                ...upcoming.map((s) => _SessionCard(s: s)),
                const SizedBox(height: 8),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(
                    icon: Icons.check_circle, iconColor: Colors.green,
                    label: "Completed", count: completed.length),
                ...completed.map((s) => _SessionCard(s: s)),
                const SizedBox(height: 8),
              ],
              if (cancelled.isNotEmpty) ...[
                _SectionHeader(
                    icon: Icons.cancel, iconColor: Colors.redAccent,
                    label: "Cancelled", count: cancelled.length),
                ...cancelled.map((s) => _SessionCard(s: s)),
              ],
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => const _SessionSkeleton(),
        ),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text("$count",
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ─── Session skeleton ─────────────────────────────────────────────────────────

class _SessionSkeleton extends StatelessWidget {
  const _SessionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 48, height: 48,
                decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 140, height: 12,
                  decoration: BoxDecoration(color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 6),
              Container(width: 90, height: 10,
                  decoration: BoxDecoration(color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6))),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(height: 10, width: 160,
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6))),
        ],
      ),
    );
  }
}

// ─── Session card ─────────────────────────────────────────────────────────────

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
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open meeting link")),
      );
    }
  }

  bool _isExpired(String? iso) {
    if (iso == null) return false;
    try {
      return DateTime.now().isAfter(DateTime.parse(iso).toLocal());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = SessionRepository();
    final s = widget.s;

    final currentUser = Supabase.instance.client.auth.currentUser!.id;
    final isTeacher = s['teacher_id'] == currentUser;
    final userData = isTeacher ? s['student_data'] : s['teacher_data'];

    final String name = userData?['name'] ?? "User";
    final String? avatar = userData?['avatar_url'];
    final String status = s['status'] ?? 'unknown';
    final String? slotTime = s['slot_time']?.toString();
    final bool expired = _isExpired(slotTime);

    // ✅ FIXED: UTC → IST via TimeUtils
    final String timeLabel = slotTime != null
        ? "${TimeUtils.formatDateLabel(slotTime)} • ${TimeUtils.formatClock(slotTime)}"
        : "—";

    Color statusColor = status == 'completed'
        ? Colors.greenAccent
        : status == 'cancelled'
        ? Colors.redAccent
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Card header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage:
                      avatar != null ? NetworkImage(avatar) : null,
                      backgroundColor: Colors.cyan.withOpacity(0.15),
                      child: avatar == null
                          ? Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 18))
                          : null,
                    ),
                    if (status == 'booked')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF161616), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTeacher ? "Student: $name" : "Teacher: $name",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Text(s['skill'] ?? "Session",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: statusColor.withOpacity(0.3), width: 0.5),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // ── Time row ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.cyan, size: 16),
                const SizedBox(width: 8),
                Text(timeLabel,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                if (expired && status == 'booked') ...[
                  const Spacer(),
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  const Text("Expired",
                      style: TextStyle(
                          color: Colors.redAccent, fontSize: 11)),
                ],
              ],
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────
          if (status == 'booked')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // JOIN
                  if (s['meeting_url'] != null)
                    Expanded(
                      child: _ActionBtn(
                        label: "Join",
                        icon: Icons.video_call_rounded,
                        color: Colors.cyan,
                        onTap: loading
                            ? null
                            : () => openMeeting(s['meeting_url'].toString()),
                      ),
                    ),
                  if (s['meeting_url'] != null) const SizedBox(width: 8),

                  // CHAT
                  Expanded(
                    child: _ActionBtn(
                      label: "Chat",
                      icon: Icons.chat_rounded,
                      color: Colors.blueAccent,
                      onTap: () => context.push('/chat/${s['id']}'),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // COMPLETE (teacher only)
                  if (isTeacher)
                    Expanded(
                      child: _ActionBtn(
                        label: loading ? "..." : "Complete",
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        onTap: loading
                            ? null
                            : () async {
                          setState(() => loading = true);
                          await repo.completeSession(s['id']);
                          ref.invalidate(sessionProvider);
                          setState(() => loading = false);
                          if (!mounted) return;
                          _showRatingDialog(context, s['id']);
                        },
                      ),
                    ),
                  if (isTeacher) const SizedBox(width: 8),

                  // CANCEL
                  _ActionBtn(
                    label: "Cancel",
                    icon: Icons.close_rounded,
                    color: Colors.redAccent,
                    onTap: loading
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
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String sessionId) {
    int rating = 5;
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rate this session",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, ss) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => ss(() => rating = i + 1),
                        child: Icon(
                          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber, size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text("$rating / 5",
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Leave a review (optional)",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Skip",
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await SessionRepository()
                  .rateSession(sessionId, rating, ctrl.text);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Submit",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.white10
              : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: onTap == null
                  ? Colors.white10
                  : color.withOpacity(0.3),
              width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: onTap == null ? Colors.white24 : color, size: 20),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? Colors.white24 : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}