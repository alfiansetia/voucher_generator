import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'router_list_page.dart';
import 'ping_tool_page.dart';
import 'ip_calculator_page.dart';
import 'network_discovery_page.dart';
import 'port_scanner_page.dart';
import 'wake_on_lan_page.dart';
import 'traceroute_page.dart';
import 'wifi_scanner_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Tools'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Utilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A complete set of tools to manage and monitor your network.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildMenuCard(
                  context,
                  'MikroTik Manager',
                  'Manage routers',
                  Icons.router,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RouterListPage()),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'Ping Tool',
                  'Check connect',
                  Icons.network_check,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PingToolPage()),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'IP Calculator',
                  'Subnetting',
                  Icons.calculate,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IpCalculatorPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'Discovery',
                  'Scan devices',
                  Icons.radar,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NetworkDiscoveryPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'Port Scanner',
                  'Check ports',
                  Icons.search,
                  Colors.teal,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PortScannerPage(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'Wake-on-LAN',
                  'Turn on PCs',
                  Icons.power_settings_new,
                  Colors.redAccent,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WakeOnLanPage()),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'Traceroute',
                  'Trace path',
                  Icons.route,
                  Colors.indigo,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TraceroutePage()),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  'WiFi Scanner',
                  'Scan nearby',
                  Icons.wifi_find,
                  Colors.cyan,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WifiScannerPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked
              ? (isDark ? Colors.white10 : Colors.grey.shade50)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isLocked
                    ? Colors.grey
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLocked ? 'Locked' : subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
