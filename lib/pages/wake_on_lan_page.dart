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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wake-on-LAN'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wake up devices remotely',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Send a "Magic Packet" to power on a computer inside your network. Ensure the target computer has Wake-on-LAN enabled in its BIOS.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _macController,
              decoration: InputDecoration(
                labelText: 'Target MAC Address',
                hintText: 'e.g., 00:1A:2B:3C:4D:5E',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.settings_ethernet),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Broadcast IP Address',
                hintText: '255.255.255.255',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.cast_connected),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendMagicPacket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.power_settings_new),
                label: const Text(
                  'SEND MAGIC PACKET',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
