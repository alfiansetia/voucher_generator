import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';
import '../models/router_model.dart';
import '../core/exceptions/router_exception.dart';
import '../core/constants/app_constants.dart';

class MikrotikRepository {
  RouterOSClient? _client;
  RouterModel? _currentRouter;

  RouterOSClient? get client => _client;
  RouterModel? get currentRouter => _currentRouter;
  bool get isConnected => _client != null;

  // ===================================================================
  // ANTRIAN TUNGGAL — mencegah FormatException akibat interleaving data
  // Catatan: JANGAN gunakan .timeout() pada _client!.talk() di dalam antrian!
  // Timeout paksa akan meninggalkan socket dalam keadaan "setengah baca",
  // menyebabkan FormatException pada perintah berikutnya.
  // ===================================================================
  Future<void>? _commandQueue;

  Future<List<Map<dynamic, dynamic>>> talk(
    String command, [
    Map<String, String>? args,
  ]) async {
    if (_client == null) throw MikrotikConnectionException('Not connected');

    final previousTask = _commandQueue;
    final completer = Completer<List<Map<dynamic, dynamic>>>();

    _commandQueue = Future(() async {
      // Tunggu antrian sebelumnya — dengan batas 30 detik sebagai pengaman deadlock
      if (previousTask != null) {
        await previousTask
            .timeout(const Duration(seconds: 30), onTimeout: () {})
            .catchError((_) {});
      }

      try {
        if (_client == null) {
          if (!completer.isCompleted) {
            completer.completeError(
              MikrotikConnectionException('Disconnected while in queue'),
            );
          }
          return;
        }
        // TANPA timeout paksa — biarkan RouterOS library mengelola socket sendiri
        // Timeout paksa = socket bocor = FormatException pada perintah berikutnya
        final res = await _client!.talk(command, args ?? {});
        if (!completer.isCompleted) completer.complete(res);
      } catch (e) {
        if (!completer.isCompleted) completer.completeError(e);
      }
    });

    return completer.future;
  }

  // ===================================================================

  Future<void> connect(RouterModel router) async {
    _commandQueue = null; // Reset antrian saat koneksi baru

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
      _commandQueue = null;
      throw MikrotikConnectionException(e.message ?? 'Connection timed out');
    } catch (e) {
      _client?.close();
      _client = null;
      _currentRouter = null;
      _commandQueue = null;
      if (e is RouterException) rethrow;
      throw MikrotikConnectionException('Failed to connect: $e');
    }
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
    _currentRouter = null;
    _commandQueue = null;
  }

  Future<Map<String, String>> getSystemResource() async {
    final Map<String, String> data = {};

    Future<void> safeTalk(
      String label,
      String command, {
      Map<String, String>? args,
      bool isCount = false,
    }) async {
      try {
        final res = await talk(command, args);
        if (res.isNotEmpty) {
          if (isCount) {
            data[label] = res.first['ret']?.toString() ?? '0';
          } else {
            res.first.forEach((k, v) => data[k.toString()] = v.toString());
          }
        } else if (isCount) {
          data[label] = '0';
        }
      } catch (e) {
        debugPrint('safeTalk error [$label]: $e');
        if (isCount) data[label] = '0';
      }
    }

    await safeTalk('system', '/system/resource/print');
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

  // getHotspotProfiles dan getHotspotServers masih tersedia untuk keperluan lain
  // tapi VoucherPage sekarang menggunakan koneksi sementara sendiri
  Future<List<Map<String, String>>> getHotspotProfiles() async {
    if (_client == null) return [];
    try {
      final res = await talk('/ip/hotspot/user/profile/print');
      final List<Map<String, String>> list = [];
      for (final item in res) {
        final Map<String, String> m = {};
        item.forEach((k, v) => m[k.toString()] = v.toString());
        if ((m['name'] ?? '').isNotEmpty) list.add(m);
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, String>>> getHotspotServers() async {
    if (_client == null) return [];
    try {
      final res = await talk('/ip/hotspot/print');
      final List<Map<String, String>> list = [];
      for (final item in res) {
        final Map<String, String> m = {};
        item.forEach((k, v) => m[k.toString()] = v.toString());
        list.add(m);
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> addHotspotUser({
    required String name,
    required String password,
    required String profile,
    String? server,
    String? comment,
  }) async {
    if (_client == null) throw MikrotikConnectionException('Not connected');
    final Map<String, String> args = {
      'name': name,
      'password': password,
      'profile': profile,
    };
    if (server != null && server != 'all') args['server'] = server;
    if (comment != null) args['comment'] = comment;
    await talk('/ip/hotspot/user/add', args);
  }
}
