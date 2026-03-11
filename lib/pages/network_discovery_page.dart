import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_tools/network_tools.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../core/constants/app_constants.dart';
import 'home_page.dart';
import '../components/ping_dialog.dart';
import 'port_scanner_page.dart';
import 'wake_on_lan_page.dart';

class NetworkDiscoveryPage extends StatefulWidget {
  const NetworkDiscoveryPage({super.key});

  @override
  State<NetworkDiscoveryPage> createState() => _NetworkDiscoveryPageState();
}

class _NetworkDiscoveryPageState extends State<NetworkDiscoveryPage> {
  bool _isScanning = false;
  final List<ActiveHost> _devices = [];
  final Map<String, String> _resolvedNames = {};
  final NetworkInfo _networkInfo = NetworkInfo();
  String? _localIp;
  StreamSubscription<ActiveHost>? _scanSubscription;
  Timer? _uiUpdateTimer;
  final List<ActiveHost> _pendingDevices = [];

  Future<void> _startScan() async {
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      final String? ip = await _networkInfo.getWifiIP();
      _localIp = ip;
      if (ip == null || ip.isEmpty || !ip.contains('.')) {
        _showError(
          'Gagal mendapatkan IP lokal yang valid. Pastikan WiFi aktif.',
        );
        if (mounted) setState(() => _isScanning = false);
        return;
      }

      final int lastDotIndex = ip.lastIndexOf('.');
      final String subnet = ip.substring(0, lastDotIndex).trim();

      // Standard scan for version 5.x
      final stream = HostScannerService.instance.getAllPingableDevices(subnet);

      _scanSubscription = stream.listen(
        (ActiveHost host) {
          _pendingDevices.add(host);
        },
        onDone: () {
          _uiUpdateTimer?.cancel();
          _updateUI();
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
            // Resolve hostnames ONLY after scan is done to avoid lag
            _resolveAllHostNames();
          }
        },
        onError: (e) {
          _uiUpdateTimer?.cancel();
          _showError('Scan error: $e');
          if (mounted) setState(() => _isScanning = false);
        },
      );

      // High interval (1s) to give CPU breathing room for the background scan
      // Update UI less frequently (1.5s) to save thread time during heavy I/O
      _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 1500), (
        timer,
      ) {
        if (_pendingDevices.isNotEmpty || _isScanning) {
          _updateUI();
        }
      });
    } catch (e) {
      _showError('Terjadi kesalahan saat scanning: $e');
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _updateUI() {
    if (!mounted) return;

    setState(() {
      if (_pendingDevices.isNotEmpty) {
        _devices.addAll(_pendingDevices);
        _pendingDevices.clear();

        _devices.sort((a, b) {
          try {
            final aParts = a.address.split('.');
            final bParts = b.address.split('.');
            if (aParts.length < 4 || bParts.length < 4) return 0;
            final aLast = int.tryParse(aParts.last) ?? 0;
            final bLast = int.tryParse(bParts.last) ?? 0;
            return aLast.compareTo(bLast);
          } catch (_) {
            return 0;
          }
        });
      }
    });
  }

  Future<void> _resolveAllHostNames() async {
    for (var host in _devices) {
      if (!mounted || _isScanning) break;
      try {
        final String? name = await host.hostName;
        if (name != null && name.isNotEmpty) {
          setState(() {
            _resolvedNames[host.address] = name;
          });
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Network Discovery'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildScanHeader(),
          if (_isScanning)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              width: double.infinity,
              color: Colors.blue.withValues(alpha: 0.05),
              child: const Row(
                children: [
                  Icon(Icons.sync, color: Colors.blue, size: 16),
                  SizedBox(width: 12),
                  Text(
                    'SCANNING IN PROGRESS...',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _devices.isEmpty && !_isScanning
                ? _buildEmptyState()
                : _buildDeviceList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : AppConstants.primaryColor,
        icon: _isScanning
            ? const Icon(
                Icons.sync,
                color: Colors.white,
              ) // Static icon while scanning
            : const Icon(Icons.search, color: Colors.white),
        label: Text(
          _isScanning ? 'SCANNING...' : 'SCAN NETWORK',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildScanHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppConstants.primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nearby Devices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Found ${_devices.length} devices on local network',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.devices_other, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No devices discovered yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap search to scan your local network',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showDeviceOptions(
    BuildContext context,
    String address,
    String deviceName,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.devices, color: Colors.blue),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.network_ping, color: Colors.orange),
              title: const Text('Ping Device'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => PingDialog(ip: address),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.teal),
              title: const Text('Scan Open Ports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PortScannerPage(initialIp: address),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.power_settings_new,
                color: Colors.redAccent,
              ),
              title: const Text('Wake-on-LAN'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WakeOnLanPage(initialIp: address),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _devices.length,
      addAutomaticKeepAlives: true,
      itemBuilder: (context, index) {
        final host = _devices[index];
        final String address = host.address;

        String deviceName = _resolvedNames[address] ?? 'Unknown Device';
        if (deviceName == 'Unknown Device' && address.endsWith('.1')) {
          deviceName = 'Gateway / Router';
        }

        return GestureDetector(
          onTap: () => _showDeviceOptions(context, address, deviceName),
          child: Card(
            key: ValueKey(address),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      host.address.endsWith('.1')
                          ? Icons.router
                          : host.address == _localIp
                          ? Icons.person
                          : Icons.laptop_mac,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                deviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (host.address == _localIp) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Network Device',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        host.address,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
