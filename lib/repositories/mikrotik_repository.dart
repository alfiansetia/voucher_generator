import 'dart:async';
import 'package:router_os_client/router_os_client.dart';
import '../models/router_model.dart';
import '../core/exceptions/router_exception.dart';
import '../core/constants/app_constants.dart';

class MikrotikRepository {
  RouterOSClient? _client;
  RouterModel? _currentRouter;

  RouterOSClient? get client => _client;
  RouterModel? get currentRouter => _currentRouter;

  Future<void> connect(RouterModel router) async {
    try {
      _currentRouter = router;
      _client = RouterOSClient(
        address: router.ip,
        user: router.username,
        password: router.password,
        port: router.port,
      );

      final success = await _client!.login().timeout(
        const Duration(seconds: AppConstants.connectionTimeout),
        onTimeout: () => throw TimeoutException(
          'Connection timed out after ${AppConstants.connectionTimeout} seconds',
        ),
      );

      if (!success) {
        throw MikrotikAuthException('Login failed for ${router.name}');
      }
    } on TimeoutException catch (e) {
      _client?.close();
      _client = null;
      _currentRouter = null;
      throw MikrotikConnectionException(e.message ?? 'Connection timed out');
    } on LoginError catch (e) {
      _client = null;
      _currentRouter = null;
      throw MikrotikAuthException('Authentication error: ${e.message}');
    } on CreateSocketError catch (e) {
      _client = null;
      _currentRouter = null;
      throw MikrotikConnectionException('Socket error: ${e.message}');
    } catch (e) {
      _client?.close();
      _client = null;
      _currentRouter = null;
      if (e is RouterException) rethrow;
      throw MikrotikConnectionException('Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
    _currentRouter = null;
  }

  bool get isConnected => _client != null;

  Future<Map<String, String>> getSystemResource() async {
    if (_client == null) throw MikrotikConnectionException('Not connected');

    final Map<String, String> data = {};

    // Helper untuk menjalankan perintah secara aman dengan format Map arguments
    Future<void> safeTalk(
      String label,
      String command, {
      Map<String, String>? args,
      bool isCount = false,
    }) async {
      try {
        final res = await _client!.talk(command, args ?? {});
        // print('Mikrotik Raw Response ($label): $res');

        if (res.isNotEmpty) {
          if (isCount) {
            // Mengambil nilai 'ret' untuk perintah count-only
            data[label] = res.first['ret']?.toString() ?? '0';
          } else {
            // Menambahkan semua data dari map pertama hasil print
            res.first.forEach((k, v) {
              data[k] = v.toString();
            });
          }
        } else if (isCount) {
          data[label] = '0';
        }
      } catch (e) {
        if (isCount) data[label] = '0';
        // print('Mikrotik Stats Error ($label): $e');
      }
    }

    // 1. Get System Resources
    await safeTalk('system', '/system/resource/print');

    // 2. Get Hotspot Stats
    await safeTalk(
      'hotspot-users-total',
      '/ip/hotspot/user/print',
      args: {'count-only': ''},
      isCount: true,
    );
    await safeTalk(
      'hotspot-users-active',
      '/ip/hotspot/active/print',
      args: {'count-only': ''},
      isCount: true,
    );

    // 3. Get PPP Stats
    await safeTalk(
      'ppp-secrets-total',
      '/ppp/secret/print',
      args: {'count-only': ''},
      isCount: true,
    );
    await safeTalk(
      'ppp-active-total',
      '/ppp/active/print',
      args: {'count-only': ''},
      isCount: true,
    );

    return data;
  }
}
