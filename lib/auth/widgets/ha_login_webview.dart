import 'package:flutter/material.dart';
import 'package:ha_flutter/auth/ha_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _redirectUriPrefix = 'https://haflutter.app/auth/callback';

class HaLoginWebView extends StatefulWidget {
  final Uri authorizationUrl;

  const HaLoginWebView({super.key, required this.authorizationUrl});

  @override
  State<HaLoginWebView> createState() => _HaLoginWebViewState();
}

class _HaLoginWebViewState extends State<HaLoginWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      )
      ..loadRequest(widget.authorizationUrl);
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url.startsWith(_redirectUriPrefix)) {
      final uri = Uri.parse(request.url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      if (code != null && state != null) {
        context.read<HaAuthService>().handleCallback(code, state);
      }
      if (mounted) Navigator.of(context).pop();
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
