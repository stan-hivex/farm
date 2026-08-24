import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '/flutter_flow/flutter_flow_util.dart';
import '/services/app_session_manager.dart';

class SocketService {
  SocketService._();

  static final SocketService _instance = SocketService._();

  factory SocketService() => _instance;

  io.Socket? _socket;
  bool _initialized = false;

  static Future<void> initialize() async {
    final service = SocketService();
    if (service._initialized) return;

    service._initialized = true;
    service._connect();
  }

  void _connect() {
    final backendUrl = dotenv.env['BACKEND_URL'] ??
      dotenv.env['API_BASE_URL'] ??
      dotenv.env['API_URL'] ??
      'http://localhost:3000';

    final normalizedUrl = backendUrl.endsWith('/ws')
        ? backendUrl
        : '$backendUrl/ws';

    _socket = io.io(
      normalizedUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNewConnection()
          .setTimeout(5000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] connected');
      _identify();
    });

    _socket!.onConnectError((error) {
      debugPrint('[Socket] connection error: $error');
    });

    _socket!.onDisconnect((reason) {
      debugPrint('[Socket] disconnected: $reason');
    });

    _socket!.on('transaction:update', (data) {
      debugPrint('[Socket] transaction:update: $data');
      AppSessionManager().refreshAppData();
    });

    _socket!.on('balance:update', (data) {
      debugPrint('[Socket] balance:update: $data');
      AppSessionManager().refreshAppData();
    });

    _socket!.on('error', (data) {
      debugPrint('[Socket] server error: $data');
    });

    _socket!.connect();
  }

  Future<void> _identify() async {
    final token = FFAppState().accessToken;
    if (token.isEmpty) {
      debugPrint('[Socket] no access token available yet');
      return;
    }

    _socket?.emit('identify', {'token': token});
    debugPrint('[Socket] identify sent');
  }

  void reconnect() {
    if (_socket == null) {
      _connect();
      return;
    }

    if (!_socket!.connected) {
      _socket!.connect();
      return;
    }

    _identify();
  }

  void dispose() {
    _socket?.disconnect();
    _socket = null;
    _initialized = false;
  }
}
