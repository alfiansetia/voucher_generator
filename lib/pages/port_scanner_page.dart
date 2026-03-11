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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedResults = List<Map<String, dynamic>>.from(_results)
      ..sort((a, b) => (a['open'] == b['open']) ? 0 : (a['open'] ? -1 : 1));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Port Scanner'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTopInput(),
          if (_isScanning)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: isDark ? Colors.white10 : Colors.blue.shade50,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? Colors.blue[400]! : AppConstants.primaryColor,
              ),
            ),
          Expanded(
            child: sortedResults.isEmpty && !_isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 48,
                          color: isDark ? Colors.white10 : Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter an IP and press Scan to find open ports.',
                          style: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: sortedResults.length,
                    itemBuilder: (context, index) {
                      final r = sortedResults[index];
                      final isOpen = r['open'] as bool;
                      final Color color = isOpen ? Colors.green : Colors.red;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOpen ? Icons.lock_open : Icons.lock,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              'Port ${r['port']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isOpen ? 'OPEN' : 'CLOSED',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _scanPorts,
        backgroundColor: _isScanning
            ? Colors.redAccent
            : AppConstants.primaryColor,
        icon: Icon(
          _isScanning ? Icons.stop : Icons.search,
          color: Colors.white,
        ),
        label: Text(
          _isScanning ? 'STOP' : 'SCAN PORTS',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTopInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _ipController,
              enabled: !_isScanning,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter IP address...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.lan, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
