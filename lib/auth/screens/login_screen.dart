import 'package:flutter/material.dart';
import 'package:ha_flutter/auth/ha_auth_service.dart';
import 'package:ha_flutter/auth/ha_oauth_params.dart';
import 'package:ha_flutter/auth/widgets/ha_login_webview.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final authService = context.read<HaAuthService>();
      final url = await authService.startLogin();
      if (url != null && mounted) {
        // Mobile: open the authorization URL in an embedded WebView.
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Sign in to Home Assistant')),
              body: HaLoginWebView(authorizationUrl: url),
            ),
          ),
        );
      }
      // Desktop: startLogin() handled the full flow; nothing to do here.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Home Assistant',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                haInstanceUrl,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 40),
              if (_loading)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
