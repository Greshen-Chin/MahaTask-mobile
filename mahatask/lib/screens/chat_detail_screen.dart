import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/session_store.dart';
import 'video_call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.isGroup,
  });

  final String id;
  final String title;
  final bool isGroup;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ChatMessage> _messages = const <ChatMessage>[];
  Timer? _polling;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _polling = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _polling?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = widget.isGroup
          ? await _chatService.getGroupMessages(widget.id)
          : await _chatService.getDirectMessages(widget.id);
      if (!mounted) return;
      setState(() => _messages = list);
      _jumpToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      if (widget.isGroup) {
        await _chatService.sendGroupMessage(groupId: widget.id, content: text);
      } else {
        await _chatService.sendDirectMessage(userId: widget.id, content: text);
      }
      _messageController.clear();
      await _loadMessages(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              final roomId = widget.isGroup
                  ? 'group-${widget.id}'
                  : (() {
                      final me = SessionStore.user?.id ?? 'me';
                      final ids = [me, widget.id]..sort();
                      return 'dm-${ids.join('-')}';
                    })();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen(
                    roomId: roomId,
                    title: widget.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.videocam_outlined, color: Colors.cyanAccent),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final mine = msg.senderId == SessionStore.user?.id;
                            return Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: mine ? Colors.cyanAccent.withOpacity(0.22) : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(msg.content, style: const TextStyle(color: Colors.white)),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.cyanAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
