import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_provider.dart';
import 'services/navigation_provider.dart';
import 'services/unread_provider.dart';

void main() {
  runApp(const MahaTaskApp());
}

class MahaTaskApp extends StatelessWidget {
  const MahaTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => UnreadProvider()),
      ],
      child: MaterialApp(
        title: 'MahaTask',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyanAccent,
            brightness: Brightness.dark,
          ),
        ),
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  AuthProvider? _auth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AuthProvider>();
    if (_auth == next) return;
    _auth?.removeListener(_onAuthChanged);
    _auth = next;
    _auth?.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final unread = context.read<UnreadProvider>();
    if (_auth?.isAuthenticated == true) {
      unread.start();
    } else {
      unread.stop();
      unread.clear();
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = context.watch<AuthProvider>().isAuthenticated;
    return authenticated ? const DashboardScreen() : const WelcomeScreen();
  }
}
