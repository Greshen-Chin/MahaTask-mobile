import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'session_store.dart';

class VideoParticipant {
  const VideoParticipant({
    required this.socketId,
    required this.userId,
  });

  final String socketId;
  final String userId;
}

class VideoCallService {
  VideoCallService();

  io.Socket? _socket;
  final List<VideoParticipant> _participants = <VideoParticipant>[];
  String? _lastError;

  List<VideoParticipant> get participants => List<VideoParticipant>.unmodifiable(_participants);
  String? get lastError => _lastError;
  bool get isConnected => _socket?.connected == true;

  void connect({
    required String roomId,
    required void Function() onChanged,
  }) {
    final token = SessionStore.accessToken;
    final userId = SessionStore.user?.id;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      _lastError = 'Session invalid. Login ulang.';
      onChanged();
      return;
    }

    final baseUrl = ApiClient().baseUrl;
    _socket?.dispose();
    _participants.clear();
    _lastError = null;

    _socket = io.io(
      '$baseUrl/video',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': <String, dynamic>{'token': token},
      },
    );

    _socket!.onConnect((_) {
      _socket!.emit('join-room', <String, dynamic>{
        'roomId': roomId,
        'userId': userId,
      });
      onChanged();
    });

    _socket!.on('room-participants', (data) {
      final map = (data is Map) ? data : null;
      final existing = map?['existingParticipants'];
      _participants
        ..clear()
        ..add(VideoParticipant(socketId: _socket!.id ?? 'self', userId: userId));
      if (existing is List) {
        for (final raw in existing) {
          if (raw is Map<String, dynamic>) {
            _participants.add(
              VideoParticipant(
                socketId: (raw['socketId'] ?? '').toString(),
                userId: (raw['userId'] ?? '').toString(),
              ),
            );
          }
        }
      }
      onChanged();
    });

    _socket!.on('user-joined', (data) {
      if (data is! Map) return;
      final socketId = (data['socketId'] ?? '').toString();
      final uid = (data['userId'] ?? '').toString();
      if (socketId.isEmpty) return;
      final exists = _participants.any((p) => p.socketId == socketId);
      if (!exists) {
        _participants.add(VideoParticipant(socketId: socketId, userId: uid));
      }
      onChanged();
    });

    _socket!.on('user-left', (data) {
      if (data is! Map) return;
      final socketId = (data['socketId'] ?? '').toString();
      _participants.removeWhere((p) => p.socketId == socketId);
      onChanged();
    });

    _socket!.on('room-full', (data) {
      _lastError = 'Room penuh. Maksimal 8 peserta.';
      onChanged();
    });

    _socket!.onConnectError((error) {
      _lastError = 'Koneksi video gagal: $error';
      onChanged();
    });

    _socket!.onError((error) {
      _lastError = 'Error video call: $error';
      onChanged();
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _participants.clear();
  }
}
