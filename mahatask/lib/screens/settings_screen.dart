import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../services/session_store.dart';
import '../services/unread_provider.dart';

enum _SettingsSection { profile, account, appearance, notifications }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection _section = _SettingsSection.profile;
  bool _marketingEmail = false;
  bool _socialEmail = false;
  bool _securityEmail = true;
  String _themeMode = 'Dark';
  final TextEditingController _nameController = TextEditingController(text: SessionStore.user?.name ?? '');
  final TextEditingController _bioController = TextEditingController(text: SessionStore.user?.bio ?? '');

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<UnreadProvider>().totalUnread;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          child: Column(
            children: [
              _menuTile(_SettingsSection.profile, Icons.person_outline, 'Profile'),
              _menuTile(_SettingsSection.account, Icons.settings_outlined, 'Account'),
              _menuTile(_SettingsSection.appearance, Icons.palette_outlined, 'Appearance'),
              _menuTile(
                _SettingsSection.notifications,
                Icons.notifications_outlined,
                'Notifications',
                trailing: unread > 0 ? '$unread' : null,
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildSectionContent(unread),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuTile(_SettingsSection value, IconData icon, String title, {String? trailing}) {
    final active = _section == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white10 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        onTap: () => setState(() => _section = value),
        leading: Icon(icon, color: active ? Colors.cyanAccent : Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: trailing == null
            ? const Icon(Icons.chevron_right, color: Colors.white38)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(trailing, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }

  Widget _buildSectionContent(int unread) {
    switch (_section) {
      case _SettingsSection.profile:
        return _profilePanel();
      case _SettingsSection.account:
        return _accountPanel();
      case _SettingsSection.appearance:
        return _appearancePanel();
      case _SettingsSection.notifications:
        return _notificationPanel(unread);
    }
  }

  Widget _panel({required Widget child}) {
    return Container(
      key: ValueKey(_section),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _profilePanel() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Public profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('This is how others will see you.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white70)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Username'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: _inputDecoration('Bio'),
          ),
          const SizedBox(height: 10),
          TextField(
            enabled: false,
            style: const TextStyle(color: Colors.white54),
            decoration: _inputDecoration(SessionStore.user?.email ?? 'email@example.com'),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7D3CF8)),
              child: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountPanel() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: 'English',
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Language'),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              color: Colors.redAccent.withOpacity(0.08),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Danger Zone', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Delete account is irreversible.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _appearancePanel() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appearance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Customize interface mode.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),
          _themeTile('Dark', Icons.dark_mode_outlined),
          const SizedBox(height: 8),
          _themeTile('Light', Icons.light_mode_outlined),
          const SizedBox(height: 8),
          _themeTile('System', Icons.phone_android_outlined),
        ],
      ),
    );
  }

  Widget _themeTile(String mode, IconData icon) {
    final active = _themeMode == mode;
    return InkWell(
      onTap: () => setState(() => _themeMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? Colors.white12 : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.cyanAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.cyanAccent : Colors.white70),
            const SizedBox(width: 8),
            Text(mode, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            if (active) const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _notificationPanel(int unread) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          Text('Unread direct messages: $unread', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _switchTile(
            title: 'Marketing emails',
            subtitle: 'Receive newsletter and product tips.',
            value: _marketingEmail,
            onChanged: (v) => setState(() => _marketingEmail = v),
          ),
          _switchTile(
            title: 'Social emails',
            subtitle: 'Friend request and group updates.',
            value: _socialEmail,
            onChanged: (v) => setState(() => _socialEmail = v),
          ),
          _switchTile(
            title: 'Security emails',
            subtitle: 'Important account alerts.',
            value: _securityEmail,
            onChanged: (v) => setState(() => _securityEmail = v),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.cyanAccent),
      ),
    );
  }
}
