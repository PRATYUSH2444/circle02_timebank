import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;

  const ChatScreen({super.key, required this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final controller = TextEditingController();

  List messages = [];

  late RealtimeChannel chatChannel;

  @override
  void initState() {
    super.initState();
    fetch();

    chatChannel = supabase.channel('chat');

    chatChannel
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        fetch();
      },
    )
        .subscribe();
  }

  Future<void> fetch() async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('session_id', widget.sessionId)
        .order('created_at');

    setState(() => messages = res);
  }

  Future<void> send() async {
    final user = supabase.auth.currentUser;

    await supabase.from('messages').insert({
      'session_id': widget.sessionId,
      'sender_id': user!.id,
      'message': controller.text,
    });

    controller.clear();
  }

  @override
  void dispose() {
    chatChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: messages.map((m) {
                final isMe = m['sender_id'] == userId;

                return Align(
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(10),
                    color: isMe ? Colors.blue : Colors.grey,
                    child: Text(m['message']),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            children: [
              Expanded(child: TextField(controller: controller)),
              IconButton(onPressed: send, icon: const Icon(Icons.send))
            ],
          )
        ],
      ),
    );
  }
}