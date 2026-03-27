import 'package:flutter/material.dart';
import '../repository/session_repository.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Sessions")),

      body: FutureBuilder(
        future: SessionRepository().getMySessions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!;

          if (sessions.isEmpty) {
            return const Center(child: Text("No sessions yet"));
          }

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (_, i) {
              final s = sessions[i];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(s['skill']),
                  subtitle: Text("Status: ${s['status']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}