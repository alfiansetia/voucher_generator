import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class WakeOnLanPage extends StatefulWidget {
  final String? initialIp;
  const WakeOnLanPage({super.key, this.initialIp});

  @override
  State<WakeOnLanPage> createState() => _WakeOnLanPageState();
}

class _WakeOnLanPageState extends State<WakeOnLanPage> {
  late final TextEditingController _macController;
  late final TextEditingController _ipController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _macController = TextEditingController();
    String broadcastIp = '255.255.255.255';
    if (widget.initialIp != null && widget.initialIp!.contains('.')) {
      final parts = widget.initialIp!.split('.');
      if (parts.length == 4) {
        broadcastIp = '${parts[0]}.${parts[1]}.${parts[2]}.255';
      }
    }
    _ipController = TextEditingController(text: broadcastIp);
  }

  Future<void> _sendMagicPacket() async {
    FocusScope.of(context).unfocus();
    final macStr = _macController.text.trim();
    final ipStr = _ipController.text.trim();

    if (macStr.isEmpty || ipStr.isEmpty) {
      _showSnackbar('Please enter valid MAC and IPv4 Broadcast addresses.');
      return;
    }

    final RegExp macRegex = RegExp(
      r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
    );
    if (!macRegex.hasMatch(macStr)) {
      _showSnackbar('Invalid MAC Address format. Example: AA:BB:CC:DD:EE:FF');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final macBytes = macStr
          .replaceAll('-', ':')
          .split(':')
          .map((s) => int.parse(s, radix: 16))
          .toList();
      final packet = <int>[...List.filled(6, 0xFF)];
      for (int i = 0; i < 16; i++) {
        packet.addAll(macBytes);
      }

      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(packet, InternetAddress(ipStr), 9);
      socket.close();

      _showSnackbar('Magic Packet sent successfully!', isSuccess: true);
    } catch (e) {
      _showSnackbar('Failed to send packet: $e');
    }

    setState(() {
      _isSending = false;
    });
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _macController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Wake-on-LAN'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInputCard(),
                  const SizedBox(height: 30),
                  _buildInstructions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wake up remote devices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Send a magic packet to a specific network device.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Column(
        children: [
          TextField(
            controller: _macController,
            enabled: !_isSending,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'MAC Address',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              hintText: 'AA:BB:CC:DD:EE:FF',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey[300],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              prefixIcon: const Icon(
                Icons.important_devices,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _ipController,
            enabled: !_isSending,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Broadcast Address',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              hintText: '255.255.255.255',
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.grey[300],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              prefixIcon: const Icon(
                Icons.sensors,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMagicPacket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'WAKE UP DEVICE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Important:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Ensure the target computer has Wake-on-LAN enabled in its BIOS/UEFI settings and network adapter properties. It must also be connected via Ethernet.',
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
      ],
    );
  }
}
