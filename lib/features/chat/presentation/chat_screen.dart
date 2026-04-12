import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/chat_user_provider.dart';
import '../../../utils/time_utils.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool _seenPending = true;

  late RealtimeChannel _channel;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _setTyping(false);
    _channel.unsubscribe();
    supabase.removeChannel(_channel);
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('session_id', widget.sessionId)
        .order('created_at', ascending: true)
        .limit(50);

    if (!mounted) return;
    setState(() {
      messages = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
    _scrollToBottom(jump: true);
    _markAsSeen();
  }

  void _subscribeRealtime() {
    _channel = supabase
        .channel('chat:${widget.sessionId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: widget.sessionId,
      ),
      callback: (payload) {
        final newMsg = Map<String, dynamic>.from(payload.newRecord);
        if (!mounted) return;
        setState(() {
          final exists = messages.any((m) => m['id'] == newMsg['id']);
          if (!exists) {
            messages.add(newMsg);
            messages.sort((a, b) =>
                DateTime.parse(a['created_at'])
                    .compareTo(DateTime.parse(b['created_at'])));
          }
        });
        _scrollToBottom();
        _seenPending = true;
        _markAsSeen();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: widget.sessionId,
      ),
      callback: (payload) {
        final updated = Map<String, dynamic>.from(payload.newRecord);
        if (!mounted) return;
        setState(() {
          final idx = messages.indexWhere((m) => m['id'] == updated['id']);
          if (idx != -1) messages[idx] = updated;
        });
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: widget.sessionId,
      ),
      callback: (payload) {
        final id = payload.oldRecord['id'];
        if (!mounted) return;
        setState(() => messages.removeWhere((m) => m['id'] == id));
      },
    )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    controller.clear();
    await _setTyping(false);

    await supabase.from('messages').insert({
      'session_id': widget.sessionId,
      'sender_id': user.id,
      'message': text,
      'seen': false,
      'created_at': TimeUtils.nowUtc(), // ✅ always UTC
    });
  }

  Future<void> _markAsSeen() async {
    if (!_seenPending) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final unseen = messages
        .where((m) => m['sender_id'] != userId && m['seen'] == false)
        .map((m) => m['id'])
        .toList();
    if (unseen.isEmpty) return;
    await supabase
        .from('messages')
        .update({'seen': true}).inFilter('id', unseen);
    _seenPending = false;
  }

  Future<void> _setTyping(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('typing_status').upsert({
      'session_id': widget.sessionId,
      'user_id': user.id,
      'is_typing': value,
    });
  }

  void _scrollToBottom({bool jump = false}) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;
      if (jump) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      } else {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(chatUserProvider(widget.sessionId));
    final currentUser = supabase.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leadingWidth: 30,
        title: userAsync.when(
          data: (user) {
            final name = user['name'] ?? "User";
            final avatar = user['avatar_url'];
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  backgroundColor: Colors.cyan.withOpacity(0.2),
                  child: avatar == null
                      ? Text(name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.cyan, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const Text("Session chat",
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            );
          },
          loading: () => const Text("Loading...",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          error: (_, __) =>
          const Text("Chat", style: TextStyle(color: Colors.white)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.chat_bubble_outline,
                      color: Colors.white24, size: 52),
                  SizedBox(height: 14),
                  Text("No messages yet\nSay hello! 👋",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white38, height: 1.6)),
                ],
              ),
            )
                : ListView.builder(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender_id'] == currentUser;
                final createdAt = msg['created_at']?.toString();

                final showDate = index == 0 ||
                    !TimeUtils.isSameDay(
                      messages[index - 1]['created_at']?.toString(),
                      createdAt,
                    );

                return Column(
                  children: [
                    if (showDate) _DateChip(createdAt),
                    _MessageBubble(
                      text: msg['message'] ?? '',
                      // ✅ FIXED: TimeUtils → correct IST time
                      time: TimeUtils.formatClock(createdAt),
                      isMe: isMe,
                      seen: msg['seen'] ?? false,
                    ),
                  ],
                );
              },
            ),
          ),
          _InputBar(
            controller: controller,
            onSend: _sendMessage,
            onTyping: _setTyping,
          ),
        ],
      ),
    );
  }
}

// ─── Date chip ────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String? isoString;
  const _DateChip(this.isoString);

  @override
  Widget build(BuildContext context) {
    final label = TimeUtils.formatDateLabel(isoString);
    if (label.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool seen;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.seen,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            top: 3, bottom: 3, left: isMe ? 64 : 0, right: isMe ? 0 : 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.cyan : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? Colors.cyan.withOpacity(0.15)
                  : Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: TextStyle(
                    color: isMe ? Colors.black : Colors.white,
                    fontSize: 15,
                    height: 1.4)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time,
                    style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.black45 : Colors.white38)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(seen ? Icons.done_all : Icons.done,
                      size: 13,
                      color: seen ? Colors.blue[700] : Colors.black38),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Future<void> Function(bool) onTyping;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onTyping,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border:
          Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (val) => onTyping(val.isNotEmpty),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Message...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1C),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    color: Colors.cyan, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}