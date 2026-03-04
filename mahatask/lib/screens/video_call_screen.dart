import 'package:flutter/material.dart';

import '../services/video_call_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.title,
  });

  final String roomId;
  final String title;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService _videoCallService = VideoCallService();

  @override
  void initState() {
    super.initState();
    _videoCallService.connect(
      roomId: widget.roomId,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _videoCallService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participants = _videoCallService.participants;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: Text('Video Call - ${widget.title}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_videoCallService.lastError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _videoCallService.lastError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _videoCallService.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: _videoCallService.isConnected ? Colors.greenAccent : Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _videoCallService.isConnected ? 'Connected' : 'Connecting...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  Text(
                    '${participants.length}/8',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: participants.isEmpty ? 1 : participants.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  if (participants.isEmpty) {
                    return _tile('Waiting for participant...', isSelf: true);
                  }
                  final p = participants[index];
                  return _tile(
                    p.userId.isEmpty ? 'Participant' : p.userId,
                    isSelf: index == 0,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(icon: Icons.mic_off_outlined, color: Colors.white24, onTap: () {}),
                  _actionButton(icon: Icons.videocam_off_outlined, color: Colors.white24, onTap: () {}),
                  _actionButton(
                    icon: Icons.call_end,
                    color: Colors.redAccent,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, {required bool isSelf}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelf
              ? [const Color(0xFF25333A), const Color(0xFF131C21)]
              : [const Color(0xFF2B2140), const Color(0xFF17131F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.person, color: Colors.white38, size: 48),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Text(
              isSelf ? '$label (You)' : label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
