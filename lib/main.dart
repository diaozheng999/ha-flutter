import 'package:flutter/material.dart';
import 'package:ha_flutter/auth/ha_auth_service.dart';
import 'package:ha_flutter/auth/ha_token_storage.dart';
import 'package:ha_flutter/auth/screens/login_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = HaAuthService(storage: HaTokenStorage());
  await authService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: authService,
      child: const HaApp(),
    ),
  );
}

class HaApp extends StatelessWidget {
  const HaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF18BCF2)),
        useMaterial3: true,
      ),
      home: const _RootScreen(),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<HaAuthService>().state;
    return switch (authState) {
      AuthState.unauthenticated || AuthState.error => const LoginScreen(),
      AuthState.authenticating => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthState.authenticated => const _HomeScreen(),
    };
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<HaAuthService>().logout(),
          ),
        ],
      ),
      body: const Center(child: Text('Connected')),
    );
  }
}
