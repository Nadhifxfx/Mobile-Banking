import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';
import 'app_settings.dart';

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;

  final StreamController<Map<String, dynamic>> _transactionController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get transactionStream =>
      _transactionController.stream;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await ApiService().getToken();
    if (token == null || token.isEmpty) return;

    final base = await AppSettings.getMiddlewareBaseUrl();
    final baseUri = Uri.parse(base);
    final socketUrl = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';

    _socket?.dispose();
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.on('transaction:new', (data) {
      if (data is Map) {
        _transactionController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onConnect((_) {
      // no-op
    });

    _socket!.onConnectError((err) {
      // no-op
    });

    _socket!.onError((err) {
      // no-op
    });
    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
