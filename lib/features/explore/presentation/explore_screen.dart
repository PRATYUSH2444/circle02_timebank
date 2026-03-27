import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../sessions/repository/session_repository.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final supabase = Supabase.instance.client;
  List users = [];

  @override
  void initState() {
    fetchUsers();
    super.initState();
  }

  Future<void> fetchUsers() async {
    final res = await supabase
        .from('users')
        .select()
        .neq('id', supabase.auth.currentUser!.id)
        .order('tokens', ascending: false);

    setState(() => users = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Explore")),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final user = users[i];

          return ListTile(
            title: Text(user['name']),
            subtitle: Text("Tokens: ${user['tokens']}"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => showBookingDialog(context, user),
          );
        },
      ),
    );
  }
}

void showBookingDialog(BuildContext context, dynamic user) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: Text("Book ${user['name']}"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Skill",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await SessionRepository().bookSession(
                  teacherId: user['id'],
                  skill: controller.text,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Session booked!")),
                );
              } catch (e) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text("Book"),
          )
        ],
      );
    },
  );
}