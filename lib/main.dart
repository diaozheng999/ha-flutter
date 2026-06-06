import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:ha_flutter/auth/ha_auth_service.dart';
import 'package:ha_flutter/auth/ha_token_storage.dart';
import 'package:ha_flutter/auth/screens/login_screen.dart';
import 'package:ha_flutter/features/app_shell.dart';
import 'package:ha_flutter/ha/ha_connection.dart';
import 'package:ha_flutter/ha/ha_providers.dart';
import 'package:ha_flutter/shared/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = HaAuthService(storage: HaTokenStorage());
  await authService.initialize();

  runApp(
    // Riverpod scope: the HA layer reads its connection from the override below,
    // bridging the existing provider-based auth into the new dashboard layer.
    riverpod.ProviderScope(
      overrides: [
        haConnectionProvider.overrideWithValue(
          AuthServiceConnection(authService),
        ),
      ],
      child: ChangeNotifierProvider.value(
        value: authService,
        child: const HaApp(),
      ),
    ),
  );
}

class HaApp extends StatelessWidget {
  const HaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Assistant',
      theme: AppTheme.dark,
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
      AuthState.authenticated => const AppShell(),
    };
  }
}
