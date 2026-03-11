import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'home_page.dart';

class IpCalculatorPage extends StatefulWidget {
  const IpCalculatorPage({super.key});

  @override
  State<IpCalculatorPage> createState() => _IpCalculatorPageState();
}

class _IpCalculatorPageState extends State<IpCalculatorPage> {
  final TextEditingController _inputController = TextEditingController(
    text: '192.168.1.1/24',
  );
  Map<String, String>? _results;

  void _calculate() {
    FocusScope.of(context).unfocus();
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    try {
      final parts = input.split('/');
      if (parts.length != 2) {
        throw Exception('Invalid format. Use IP/CIDR (e.g. 192.168.1.1/24)');
      }

      final ipStr = parts[0];
      final cidr = int.parse(parts[1]);

      if (cidr < 0 || cidr > 32) {
        throw Exception('CIDR must be between 0 and 32');
      }

      final ipParts = ipStr.split('.').map(int.parse).toList();
      if (ipParts.length != 4 || ipParts.any((p) => p < 0 || p > 255)) {
        throw Exception('Invalid IP address');
      }

      int ipInt =
          (ipParts[0] << 24) |
          (ipParts[1] << 16) |
          (ipParts[2] << 8) |
          ipParts[3];
      int maskInt = cidr == 0 ? 0 : (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF;
      int networkInt = ipInt & maskInt;
      int wildcardInt = ~maskInt & 0xFFFFFFFF;
      int broadcastInt = networkInt | wildcardInt;

      String ipClass = 'Unknown';
      int firstOctet = ipParts[0];
      if (firstOctet >= 1 && firstOctet <= 126) {
        ipClass = 'A';
      } else if (firstOctet >= 128 && firstOctet <= 191) {
        ipClass = 'B';
      } else if (firstOctet >= 192 && firstOctet <= 223) {
        ipClass = 'C';
      } else if (firstOctet >= 224 && firstOctet <= 239) {
        ipClass = 'D (Multicast)';
      } else if (firstOctet >= 240 && firstOctet <= 255) {
        ipClass = 'E (Experimental)';
      }

      bool isPrivate =
          (firstOctet == 10) ||
          (firstOctet == 172 && (ipParts[1] >= 16 && ipParts[1] <= 31)) ||
          (firstOctet == 192 && ipParts[1] == 168) ||
          (firstOctet == 127);

      setState(() {
        _results = {
          'IP Address': ipStr,
          'IP Class': 'Class $ipClass',
          'IP Type': isPrivate ? 'Private (Local)' : 'Public (Internet)',
          'Network': _intToIp(networkInt),
          'Netmask': _intToIp(maskInt),
          'Wildcard': _intToIp(wildcardInt),
          'Broadcast': _intToIp(broadcastInt),
          'CIDR': '/$cidr',
          'First Host': cidr < 31 ? _intToIp(networkInt + 1) : 'N/A',
          'Last Host': cidr < 31 ? _intToIp(broadcastInt - 1) : 'N/A',
          'Total Hosts': '${pow(2, 32 - cidr).toInt()}',
          'Usable Hosts':
              '${cidr < 31 ? pow(2, 32 - cidr).toInt() - 2 : (cidr == 32 ? 1 : 2)}',
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
        ),
      );
    }
  }

  String _intToIp(int ip) {
    return [
      (ip >> 24) & 0xFF,
      (ip >> 16) & 0xFF,
      (ip >> 8) & 0xFF,
      ip & 0xFF,
    ].join('.');
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('IP Calculator'),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_results != null) _buildResultsList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _calculate,
        backgroundColor: AppConstants.primaryColor,
        label: const Text(
          'CALCULATE',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.bolt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subnetting Tools',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'IP Address & Mask',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _inputController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'e.g. 192.168.1.1/24',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                suffixIcon: Icon(Icons.search, color: Colors.white70),
              ),
              onSubmitted: (_) => _calculate(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _results!.entries
            .map((e) => _buildResultItem(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _buildResultItem(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isMain =
        title == 'Network' || title == 'Netmask' || title == 'Broadcast';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isMain
              ? AppConstants.primaryColor.withValues(alpha: 0.2)
              : (isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black26
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isMain
                      ? AppConstants.primaryColor
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
          Icon(
            _getIconForTitle(title),
            color: isMain
                ? AppConstants.primaryColor.withValues(alpha: 0.5)
                : (isDark ? Colors.white24 : Colors.grey[300]),
            size: 20,
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'IP Address':
        return Icons.location_on_outlined;
      case 'IP Class':
        return Icons.label_outline;
      case 'IP Type':
        return Icons.public_outlined;
      case 'Network':
        return Icons.lan_outlined;
      case 'Netmask':
        return Icons.grid_on;
      case 'Broadcast':
        return Icons.podcasts;
      case 'Total Hosts':
        return Icons.groups_outlined;
      case 'Usable Hosts':
        return Icons.check_circle_outline;
      case 'First Host':
        return Icons.start;
      case 'Last Host':
        return Icons.stop;
      default:
        return Icons.info_outline;
    }
  }
}
