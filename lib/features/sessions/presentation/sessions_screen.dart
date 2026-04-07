import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../repository/session_repository.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final repo = SessionRepository();

  List sessions = [];
  bool isLoading = true;

  late TabController tabController;
  late RealtimeChannel channel;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);

    fetch();

    // 🔥 REALTIME FIXED
    channel = supabase.channel('sessions_changes')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'sessions',
        callback: (_) => fetch(),
      )
      ..subscribe();
  }

  @override
  void dispose() {
    channel.unsubscribe();
    tabController.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    try {
      final user = supabase.auth.currentUser;

      final res = await supabase
          .from('sessions')
          .select()
          .or('teacher_id.eq.${user!.id},student_id.eq.${user.id}')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        sessions = res;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String timeLeft(DateTime end) {
    final diff = end.difference(DateTime.now());
    if (diff.isNegative) return "Ended";
    return "${diff.inMinutes} mins left";
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sessions"),

        // 🔥 FIXED TAB BAR
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Completed"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: tabController,
        children: [
          buildList("booked", userId),
          buildList("completed", userId),
          buildList("cancelled", userId),
        ],
      ),
    );
  }

  Widget buildList(String status, String userId) {
    final list = sessions.where((e) => e['status'] == status).toList();

    if (list.isEmpty) {
      return const Center(
        child: Text("No sessions",
            style: TextStyle(color: Colors.white70)),
      );
    }

    return RefreshIndicator(
      onRefresh: fetch,
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];

          final isTeacher = s['teacher_id'] == userId;
          final time = DateTime.parse(s['slot_time']);
          final end = DateTime.parse(s['end_time']);

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(
                "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}",
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeLeft(end)),
                  Text(isTeacher
                      ? "Teaching"
                      : "Learning"),
                ],
              ),

              trailing: Wrap(
                spacing: 8,
                children: [
                  if (s['meeting_url'] != null)
                    IconButton(
                      icon: const Icon(Icons.video_call),
                      onPressed: () {
                        launchUrl(Uri.parse(s['meeting_url']));
                      },
                    ),

                  if (status == "booked" && isTeacher)
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await repo.completeSession(s['id']);
                        fetch();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Session completed")),
                        );
                      },
                    ),

                  if (status == "booked")
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () async {
                        await repo.cancelSession(s['id']);
                        fetch();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Session cancelled")),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}