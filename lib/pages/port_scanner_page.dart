import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class PortScannerPage extends StatefulWidget {
  final String? initialIp;
  const PortScannerPage({super.key, this.initialIp});

  @override
  State<PortScannerPage> createState() => _PortScannerPageState();
}

class _PortScannerPageState extends State<PortScannerPage> {
  late final TextEditingController _ipController;
  bool _isScanning = false;
  double _progress = 0;
  final List<Map<String, dynamic>> _results = [];

  final List<int> _commonPorts = [
    20,
    21,
    22,
    23,
    25,
    53,
    67,
    68,
    80,
    110,
    119,
    123,
    143,
    161,
    162,
    443,
    445,
    3389,
    3306,
    5432,
    8080,
    8291,
    8728,
    8729,
  ];

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.initialIp);
  }

  Future<void> _scanPorts() async {
    FocusScope.of(context).unfocus();
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an IP address.')),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _results.clear();
      _progress = 0;
    });

    for (int i = 0; i < _commonPorts.length; i++) {
      if (!mounted || !_isScanning) break;

      final port = _commonPorts[i];
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(milliseconds: 500),
        );
        socket.destroy();
        _results.add({'port': port, 'open': true});
      } catch (e) {
        _results.add({'port': port, 'open': false});
      }

      setState(() {
        _progress = (i + 1) / _commonPorts.length;
      });
    }

    setState(() {
      _isScanning = false;
      _progress = 1.0;
    });
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sort results to show open ports at the top
    final sortedResults = List<Map<String, dynamic>>.from(_results)
      ..sort((a, b) => (a['open'] == b['open']) ? 0 : (a['open'] ? -1 : 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Port Scanner'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Target IP Address',
                hintText: 'e.g., 192.168.1.1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.computer),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 20),
            if (_isScanning || _progress > 0)
              Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toInt()}% scanned',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Expanded(
              child: sortedResults.isEmpty && !_isScanning
                  ? const Center(
                      child: Text(
                        'Enter an IP and press Scan to find open ports.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sortedResults.length,
                      itemBuilder: (context, index) {
                        final r = sortedResults[index];
                        final isOpen = r['open'] as bool;
                        return Card(
                          color: isOpen
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          child: ListTile(
                            leading: Icon(
                              isOpen ? Icons.lock_open : Icons.lock,
                              color: isOpen ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              'Port ${r['port']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOpen
                                    ? Colors.green.shade900
                                    : Colors.red.shade900,
                              ),
                            ),
                            trailing: Text(
                              isOpen ? 'OPEN' : 'CLOSED',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOpen ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _scanPorts,
        backgroundColor: _isScanning ? Colors.red : AppConstants.primaryColor,
        icon: Icon(
          _isScanning ? Icons.stop : Icons.search,
          color: Colors.white,
        ),
        label: Text(
          _isScanning ? 'STOP' : 'SCAN PORTS',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
