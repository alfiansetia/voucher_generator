import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'router_list_page.dart';
import 'ping_tool_page.dart';
import 'ip_calculator_page.dart';
import 'network_discovery_page.dart';
import 'port_scanner_page.dart';
import 'wake_on_lan_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Text(
              'Network Utilities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'A complete set of tools to manage and monitor your network.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                  'Manage your routers',
                  Icons.router,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RouterListPage(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Ping Tool',
                  'Check connectivity',
                  Icons.network_check,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PingToolPage(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'IP Calculator',
                  'Subnetting made easy',
                  Icons.calculate,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IpCalculatorPage(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Network Discovery',
                  'Scan devices in network',
                  Icons.radar,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NetworkDiscoveryPage(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Port Scanner',
                  'Check open ports',
                  Icons.search,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PortScannerPage(),
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Wake-on-LAN',
                  'Turn on computers',
                  Icons.power_settings_new,
                  Colors.redAccent,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WakeOnLanPage(),
                    ),
                  ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      color: isLocked ? Colors.grey.shade50 : Colors.white,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey[200]
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isLocked ? Colors.grey : color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isLocked ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLocked ? 'Locked' : subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
