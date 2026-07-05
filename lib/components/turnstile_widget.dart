import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TurnstileWidget extends StatefulWidget {
  const TurnstileWidget({
    super.key,
    required this.siteKey,
    required this.onTokenChanged,
    this.onStatusChanged,
  });

  final String siteKey;
  final ValueChanged<String> onTokenChanged;
  final ValueChanged<String>? onStatusChanged;

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final WebViewController _controller;
  bool _isReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TurnstileChannel',
        onMessageReceived: (message) {
          final rawMessage = message.message;
          if (rawMessage.isEmpty) {
            widget.onTokenChanged('');
            return;
          }

          try {
            final decoded = jsonDecode(rawMessage) as Map<String, dynamic>;
            final type = decoded['type']?.toString() ?? '';
            final value = decoded['value']?.toString() ?? '';

            if (type == 'token') {
              widget.onTokenChanged(value);
              setState(() {
                _isReady = value.isNotEmpty;
                _errorMessage = null;
              });
            } else if (type == 'error') {
              setState(() {
                _errorMessage =
                    value.isNotEmpty ? value : 'Verification failed';
              });
            }
          } catch (_) {
            widget.onTokenChanged(rawMessage);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            setState(() {
              _errorMessage = error.description;
            });
          },
        ),
      );

    if (widget.siteKey.isNotEmpty) {
      final html = _buildHtml(widget.siteKey);
      _controller.loadRequest(
        Uri.dataFromString(
          html,
          mimeType: 'text/html',
          encoding: utf8,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.siteKey.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security check',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete the challenge to continue.',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: WebViewWidget(controller: _controller),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        if (_isReady) ...[
          const SizedBox(height: 8),
          const Text(
            'Challenge completed',
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      ],
    );
  }

  String _buildHtml(String siteKey) {
    return '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      body {
        margin: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        background: transparent;
        padding: 8px;
      }
      #wrapper {
        width: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
      }
    </style>
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
  </head>
  <body>
    <div id="wrapper">
      <div id="cf-turnstile"></div>
    </div>
    <script>
      window.addEventListener('load', function () {
        if (window.turnstile) {
          window.turnstile.render('#cf-turnstile', {
            sitekey: '$siteKey',
            callback: function (token) {
              TurnstileChannel.postMessage(JSON.stringify({ type: 'token', value: token }));
            },
            'expired-callback': function () {
              TurnstileChannel.postMessage(JSON.stringify({ type: 'token', value: '' }));
            },
            'error-callback': function () {
              TurnstileChannel.postMessage(JSON.stringify({ type: 'error', value: 'Challenge failed' }));
            }
          });
        } else {
          TurnstileChannel.postMessage(JSON.stringify({ type: 'error', value: 'Turnstile script did not load' }));
        }
      });
    </script>
  </body>
</html>
''';
  }
}
