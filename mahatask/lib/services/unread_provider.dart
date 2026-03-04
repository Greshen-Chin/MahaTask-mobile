import 'dart:async';

import 'package:flutter/foundation.dart';

import 'chat_service.dart';

class UnreadProvider extends ChangeNotifier {
  UnreadProvider({ChatService? chatService}) : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  Timer? _timer;
  Map<String, int> _directUnreadByUser = const <String, int>{};
  bool _loading = false;

  Map<String, int> get directUnreadByUser => _directUnreadByUser;
  bool get isLoading => _loading;
  int get totalUnread => _directUnreadByUser.values.fold<int>(0, (a, b) => a + b);

  void start() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final counts = await _chatService.getDirectUnreadCounts();
      _directUnreadByUser = counts;
    } catch (_) {
      // Keep last known unread counts if refresh fails.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _directUnreadByUser = const <String, int>{};
    notifyListeners();
  }
}
