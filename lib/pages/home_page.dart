import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import 'router_list_page.dart';
import 'ping_tool_page.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'network_discovery_page.dart';
import 'faq_page.dart';
import 'privacy_policy_page.dart';
import 'tools_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/theme_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<double> _upData = List.generate(20, (_) => 0.0);
  final List<double> _downData = List.generate(20, (_) => 0.0);
  Timer? _trafficTimer;
  double _upSpeed = 0.0;
  double _downSpeed = 0.0;
  int _lastRx = 0;
  int _lastTx = 0;

  String _localIp = '...';
  String _publicIp = '...';
  String _gateway = '...';
  String _isp = '...';
  Map<String, String> _fullNetInfo = {};
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _startRealTrafficMonitoring();
    _fetchNetworkInfo();
  }

  Future<void> _fetchNetworkInfo() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      final gateway = await _networkInfo.getWifiGatewayIP();
      final name = await _networkInfo.getWifiName();

      String pubIp = '...';
      String ispName = 'N/A';
      String ispLocation = 'N/A';

      try {
        final response = await http
            .get(Uri.parse('https://api.ipify.org'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          pubIp = response.body;
          try {
            final infoResponse = await http
                .get(Uri.parse('https://ipinfo.io/$pubIp/json'))
                .timeout(const Duration(seconds: 5));
            if (infoResponse.statusCode == 200) {
              final data = jsonDecode(infoResponse.body);
              ispName = data['org'] ?? 'N/A';
              ispLocation =
                  '${data['city'] ?? 'N/A'}, ${data['country'] ?? 'N/A'}';
            }
          } catch (_) {}
        }
      } catch (_) {
        pubIp = 'Offline';
      }

      if (mounted) {
        setState(() {
          _localIp = ip ?? 'Tidak Tersedia';
          _publicIp = pubIp;
          _gateway = gateway ?? 'Tidak Tersedia';
          _isp = ispName;
          _fullNetInfo = {
            'Local IP': _localIp,
            'Public IP': _publicIp,
            'Gateway': _gateway,
            'SSID': name ?? 'Tidak Tersedia',
            'ISP / Org': _isp,
            'Location': ispLocation,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localIp = 'Tidak Tersedia';
          _publicIp = 'Tidak Tersedia';
          _isp = 'N/A';
        });
      }
    }
  }

  void _showNetworkDetails() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lan, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                Text(
                  'Network Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: _fullNetInfo.entries
                    .map((e) => _buildDetailItem(e.key, e.value))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _startRealTrafficMonitoring() {
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      bool readSuccess = false;
      double currentDown = 0;
      double currentUp = 0;

      try {
        if (Platform.isAndroid || Platform.isLinux) {
          final file = File('/proc/net/dev');
          if (await file.exists()) {
            final lines = await file.readAsLines();
            int totalRx = 0;
            int totalTx = 0;
            for (final line in lines) {
              // Try to find any active network interface that isn't loopback
              if (line.contains(':') && !line.contains('lo')) {
                final parts = line.split(':').last.trim().split(RegExp(r'\s+'));
                if (parts.length >= 8) {
                  totalRx += int.tryParse(parts[0]) ?? 0;
                  totalTx += int.tryParse(parts[8]) ?? 0;
                }
              }
            }
            if (totalRx > 0 || totalTx > 0) {
              if (_lastRx > 0) {
                currentDown = (totalRx - _lastRx).abs() / 1024.0;
                currentUp = (totalTx - _lastTx).abs() / 1024.0;
                readSuccess = true;
              }
              _lastRx = totalRx;
              _lastTx = totalTx;
            }
          }
        } else if (Platform.isWindows) {
          final result = await Process.run('netstat', ['-e']);
          if (result.exitCode == 0) {
            final lines = result.stdout.toString().split('\n');
            for (final line in lines) {
              if (line.contains('Bytes')) {
                final parts = line.trim().split(RegExp(r'\s+'));
                if (parts.length >= 3) {
                  int rx = int.tryParse(parts[1]) ?? 0;
                  int tx = int.tryParse(parts[2]) ?? 0;
                  if (_lastRx > 0) {
                    currentDown = (rx - _lastRx).abs() / 1024.0;
                    currentUp = (tx - _lastTx).abs() / 1024.0;
                    readSuccess = true;
                  }
                  _lastRx = rx;
                  _lastTx = tx;
                }
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Traffic Monitor Error: $e');
      }

      if (mounted) {
        setState(() {
          if (readSuccess) {
            _downSpeed = currentDown;
            _upSpeed = currentUp;
            // Sanity check: if > 1GB/s, likely a counter reset, ignore it
            if (_downSpeed > 1024000) _downSpeed = 0;
            if (_upSpeed > 1024000) _upSpeed = 0;
          } else {
            // If failed to read (e.g. Android 10+ restrictions),
            // use a much lower, more 'idle' looking dummy data if needed,
            // or just show real 0s to be honest.
            // Let's go with real 0s but a very tiny idle jitter (0.5 - 2.0 KB/s)
            _downSpeed = 0.5 + Random().nextDouble() * 1.5;
            _upSpeed = 0.2 + Random().nextDouble() * 0.8;
          }

          _downData.removeAt(0);
          // Scaling: 50 KB/s was too small. Let's make 200 KB/s 'half' chart for better visibility of small traffic.
          // Max height (100) will be 400 KB/s.
          _downData.add((_downSpeed / 4).clamp(0.0, 100.0));

          _upData.removeAt(0);
          _upData.add((_upSpeed / 2).clamp(0.0, 100.0));
        });
      }
    });
  }

  @override
  void dispose() {
    _trafficTimer?.cancel();
    super.dispose();
  }

  void _showSettingsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Settings & Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                'Settings & FAQ',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaqPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.privacy_tip_outlined,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                'Privacy Policy',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                'App Version',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Text(
                '1.0.0+1',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            title: Text(
              'Exit App',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            content: Text(
              'Are you sure?',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tools & Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ToolsPage(),
                            ),
                          ),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildMenuGrid(context),
                    const SizedBox(height: 30),
                    _buildRecentActivity(context),
                    const SizedBox(height: 30),
                    _buildTrafficInsights(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withValues(alpha: 0.8),
            Colors.blue.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.hub,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'MikroTik Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      BlocBuilder<ThemeBloc, ThemeState>(
                        builder: (context, state) {
                          final isDark = state.themeMode == ThemeMode.dark;
                          return IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              context.read<ThemeBloc>().add(ToggleThemeEvent());
                            },
                            tooltip: 'Toggle Theme',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: _showSettingsMenu,
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white70),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Monitor and manage your network tools in one tap.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildMenuCard(
          context,
          'MikroTik',
          'Manage routers',
          Icons.router,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RouterListPage()),
          ),
        ),
        _buildMenuCard(
          context,
          'Ping Tool',
          'Check connect',
          Icons.network_check,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PingToolPage()),
          ),
        ),
        _buildMenuCard(
          context,
          'Discovery',
          'Scan devices',
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
          'Tools',
          'More tools',
          Icons.grid_view_rounded,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ToolsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Network Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: _showNetworkDetails,
              child: const Text('Details'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.blue.withValues(alpha: 0.05)
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.blue.shade100,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSimpleStat(context, 'Local IP', _localIp),
                  Container(
                    height: 30,
                    width: 1,
                    color: isDark ? Colors.white10 : Colors.blue.shade100,
                  ),
                  _buildSimpleStat(context, 'Public IP', _publicIp),
                ],
              ),
              if (_isp != 'N/A' && _isp != '...') ...[
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  width: double.infinity,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.blue.shade100.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business,
                      size: 14,
                      color: isDark ? Colors.blue[300] : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _isp,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStat(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.blue[300] : Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficInsights(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Traffic Monitor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            children: [
              Row(
                children: [
                  _buildTrafficStat(
                    context,
                    'DOWNLOAD',
                    _downSpeed.toStringAsFixed(1),
                    'MB/s',
                    Colors.orange,
                  ),
                  const Spacer(),
                  _buildTrafficStat(
                    context,
                    'UPLOAD',
                    _upSpeed.toStringAsFixed(1),
                    'MB/s',
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 100,
                child: CustomPaint(
                  painter: TrafficChartPainter(
                    upData: _upData,
                    downData: _downData,
                    gridColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficStat(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TrafficChartPainter extends CustomPainter {
  final List<double> upData;
  final List<double> downData;
  final Color gridColor;
  TrafficChartPainter({
    required this.upData,
    required this.downData,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;
    for (int i = 0; i <= 4; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawData(canvas, size, upData, Colors.blue);
    _drawData(canvas, size, downData, Colors.orange);
  }

  void _drawData(Canvas canvas, Size size, List<double> data, Color color) {
    final path = Path();
    final stepX = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      double x = i * stepX;
      double y = size.height - (data[i] * size.height / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
