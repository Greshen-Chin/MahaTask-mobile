import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/social_service.dart';
import '../services/unread_provider.dart';
import 'add_friend_screen.dart';
import 'chat_detail_screen.dart';

enum _MessageTab { group, direct }

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with AutomaticKeepAliveClientMixin {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalUnread = context.watch<UnreadProvider>().totalUnread;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final hintColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final badgeBg = isDark
        ? Colors.redAccent.withOpacity(0.2)
        : const Color(0xFFFEE2E2);
    final badgeText = isDark ? Colors.redAccent : const Color(0xFFB91C1C);

    final body = SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (totalUnread > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$totalUnread unread',
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddFriendScreen(),
                      ),
                    );
                    await _load();
                  },
                  icon: Icon(
                    Icons.person_add_alt_1_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Chat lebih clean dengan gaya WhatsApp.',
              style: TextStyle(color: hintColor, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildTabChip(
                  title: 'Group',
                  active: _tab == _MessageTab.group,
                  onTap: () => setState(() => _tab = _MessageTab.group),
                ),
                const SizedBox(width: 8),
                _buildTabChip(
                  title: 'Direct',
                  active: _tab == _MessageTab.direct,
                  onTap: () => setState(() => _tab = _MessageTab.direct),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
    );
  }

  Widget _buildTabChip({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark
        ? Colors.cyanAccent.withOpacity(0.16)
        : Theme.of(context).colorScheme.primary.withOpacity(0.14);
    final inactiveBg = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    final activeText = Theme.of(context).colorScheme.primary;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: active ? activeText : inactiveText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_groups.isEmpty) {
      return Text(
        'Belum ada group.',
        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
      );
    }
    return Column(
      children: _groups
          .map((group) {
            return _MessageCard(
              title: group.name,
              subtitle: '${group.members.length} members',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      id: group.id,
                      title: group.name,
                      isGroup: true,
                    ),
                  ),
                ).then((_) => _load());
              },
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildDirectList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_friends.isEmpty) {
      return Text(
        'Belum ada teman.',
        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
      );
    }
    return Column(
      children: _friends
          .map((friend) {
            final code = friend.userCode?.isNotEmpty == true
                ? ' · ${friend.userCode}'
                : '';
            final unread = _unreadByUser[friend.id] ?? 0;
            return _MessageCard(
              title: friend.name,
              subtitle: unread > 0
                  ? 'Pesan belum dibaca$code'
                  : 'Tap untuk mulai chat$code',
              unreadCount: unread,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      id: friend.id,
                      title: friend.name,
                      isGroup: false,
                    ),
                  ),
                ).then((_) => _load());
              },
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildError() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          TextButton(
            onPressed: _load,
            child: Text(
              'Retry',
              style: TextStyle(
                color: isDark ? Colors.cyanAccent : const Color(0xFF0EA5A8),
              ),
            ),
          ),
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
    this.unreadCount = 0,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF181818) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    final iconBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);
    final chevronColor = isDark ? Colors.white30 : const Color(0xFF94A3B8);
    final label = title.trim();
    final avatarLabel = label.isEmpty ? '?' : label[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBg,
                  child: Text(
                    avatarLabel,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8, right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
