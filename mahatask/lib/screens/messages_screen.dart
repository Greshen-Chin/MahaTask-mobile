import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/social_service.dart';
import '../services/session_store.dart';
import '../services/unread_provider.dart';
import 'add_friend_screen.dart';
import 'chat_detail_screen.dart';
import 'video_call_screen.dart';

enum _MessageTab { group, direct }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with AutomaticKeepAliveClientMixin {
  final SocialService _socialService = SocialService();

  _MessageTab _tab = _MessageTab.group;
  bool _loading = true;
  String? _error;
  List<SocialGroup> _groups = const <SocialGroup>[];
  List<SocialUser> _friends = const <SocialUser>[];
  Map<String, int> _unreadByUser = const <String, int>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Future.wait<dynamic>([
        _socialService.getGroups(),
        _socialService.getFriends(),
      ]);
      if (!mounted) return;
      setState(() {
        _groups = data[0] as List<SocialGroup>;
        _friends = data[1] as List<SocialUser>;
        _unreadByUser = context.read<UnreadProvider>().directUnreadByUser;
      });
      await context.read<UnreadProvider>().refresh();
      if (!mounted) return;
      setState(() {
        _unreadByUser = context.read<UnreadProvider>().directUnreadByUser;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final totalUnread = context.watch<UnreadProvider>().totalUnread;

    final body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (totalUnread > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$totalUnread unread',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                    );
                    await _load();
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.cyanAccent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTabChip(title: 'Group', active: _tab == _MessageTab.group, onTap: () => setState(() => _tab = _MessageTab.group)),
                const SizedBox(width: 8),
                _buildTabChip(title: 'Direct', active: _tab == _MessageTab.direct, onTap: () => setState(() => _tab = _MessageTab.direct)),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
              )
            else if (_error != null)
              _buildError()
            else if (_tab == _MessageTab.group)
              _buildGroupList()
            else
              _buildDirectList(),
          ],
        ),
      ),
    );

    if (widget.embedded) return body;
    return Scaffold(backgroundColor: const Color(0xFF0D0D0D), body: body);
  }

  Widget _buildTabChip({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent.withOpacity(0.18) : Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: active ? Colors.cyanAccent : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return const Text('Belum ada group.', style: TextStyle(color: Colors.white38));
    }
    return Column(
      children: _groups.map((group) {
        return _MessageCard(
          title: group.name,
          subtitle: '${group.members.length} members',
          onVideoTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  roomId: 'group-${group.id}',
                  title: group.name,
                ),
              ),
            );
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(id: group.id, title: group.name, isGroup: true),
              ),
            ).then((_) => _load());
          },
        );
      }).toList(growable: false),
    );
  }

  Widget _buildDirectList() {
    if (_friends.isEmpty) {
      return const Text('Belum ada teman.', style: TextStyle(color: Colors.white38));
    }
    return Column(
      children: _friends.map((friend) {
        final code = friend.userCode?.isNotEmpty == true ? ' - ${friend.userCode}' : '';
        final unread = _unreadByUser[friend.id] ?? 0;
        return _MessageCard(
          title: friend.name,
          subtitle: unread > 0 ? 'Direct message$code - $unread unread' : 'Direct message$code',
          unreadCount: unread,
          onVideoTap: () {
            final me = SessionStore.user?.id ?? 'me';
            final ids = [me, friend.id]..sort();
            final roomId = 'dm-${ids.join('-')}';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoCallScreen(
                  roomId: roomId,
                  title: friend.name,
                ),
              ),
            );
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(id: friend.id, title: friend.name, isGroup: false),
              ),
            ).then((_) => _load());
          },
        );
      }).toList(growable: false),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 8),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onVideoTap,
    this.unreadCount = 0,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onVideoTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black38,
                  child: Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onVideoTap,
                  icon: const Icon(Icons.videocam_outlined, color: Colors.cyanAccent, size: 20),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                const Icon(Icons.chevron_right, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
