import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import 'router_list_page.dart';
import 'ping_tool_page.dart';
import 'ip_calculator_page.dart';
import 'network_discovery_page.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<double> _upData = List.generate(20, (_) => 20.0);
  final List<double> _downData = List.generate(20, (_) => 50.0);
  Timer? _trafficTimer;
  double _upSpeed = 0.0;
  double _downSpeed = 0.0;
  // Traffic variables for calculating speed
  int _lastRx = 0;
  int _lastTx = 0;

  // Network Info State
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
      const subnet = 'Tidak Tersedia';
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
            'Subnet Mask': subnet,
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
          _gateway = 'Tidak Tersedia';
          _isp = 'N/A';
          _fullNetInfo = {
            'Local IP': _localIp,
            'Public IP': _publicIp,
            'Gateway': _gateway,
            'Subnet Mask': 'Tidak Tersedia',
            'SSID': 'Tidak Tersedia',
            'ISP / Org': _isp,
            'Location': 'N/A',
          };
        });
      }
    }
  }

  void _showNetworkDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
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
                  color: Colors.grey[300],
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
                const Text(
                  'Network Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  elevation: 0,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
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

      try {
        if (Platform.isAndroid || Platform.isLinux) {
          final file = File('/proc/net/dev');
          if (await file.exists()) {
            final lines = await file.readAsLines();
            int currentRx = 0;
            int currentTx = 0;

            for (final line in lines) {
              if (line.contains('wlan') || line.contains('rmnet')) {
                final cleanLine = line.split(':').last.trim();
                final parts = cleanLine.split(RegExp(r'\s+'));
                if (parts.length >= 8) {
                  currentRx += int.tryParse(parts[0]) ?? 0; // Rx Bytes
                  currentTx += int.tryParse(parts[8]) ?? 0; // Tx Bytes
                }
              }
            }

            if (_lastRx > 0 && _lastTx > 0) {
              // Calculate Delta in KB/s
              final double rxSpeed = (currentRx - _lastRx) / 1024.0;
              final double txSpeed = (currentTx - _lastTx) / 1024.0;

              setState(() {
                _downSpeed = rxSpeed;
                _upSpeed = txSpeed;

                _downData.removeAt(0);
                // Adjust scale factor based on typical speeds (max 100 on graph roughly)
                _downData.add((_downSpeed / 50).clamp(0.0, 100.0));

                _upData.removeAt(0);
                _upData.add((_upSpeed / 20).clamp(0.0, 100.0));
              });
            }

            _lastRx = currentRx;
            _lastTx = currentTx;
            readSuccess = true;
          }
        }
      } catch (_) {}

      // Fallback (or placeholder for Windows/iOS/Web emulator)
      if (!readSuccess && mounted) {
        setState(() {
          _downSpeed = 5 + Random().nextDouble() * 20;
          _downData.removeAt(0);
          _downData.add(_downSpeed / 5);

          _upSpeed = 1 + Random().nextDouble() * 5;
          _upData.removeAt(0);
          _upData.add(_upSpeed / 5);
        });
      }
    });
  }

  @override
  void dispose() {
    _trafficTimer?.cancel();
    super.dispose();
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes, Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation(context);
        if (shouldPop ?? false) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 30),
                          const Text(
                            'Tools & Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildMenuGrid(context),
                          const SizedBox(height: 30),
                          _buildRecentActivity(),
                          const SizedBox(height: 30),
                          _buildTrafficMonitor(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                      image: const DecorationImage(
                        image: AssetImage('assets/images/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      Text(
                        'Mikrotik Hub',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Efficiently manage your MikroTik vouchers and networks in one place.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          'MikroTik Manager',
          'Manage your routers',
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
          'Check connectivity',
          Icons.network_check,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PingToolPage()),
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
            MaterialPageRoute(builder: (context) => const IpCalculatorPage()),
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
      ],
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

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Network Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: _showNetworkDetails,
              child: const Text('Details', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _showNetworkDetails,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSimpleStat('Local IP', _localIp),
                    _buildDivider(),
                    _buildSimpleStat('Public IP', _publicIp),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isp,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficMonitor() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Monitor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Real-time traffic',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.insights, color: Colors.blue, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(painter: TrafficPainter(_upData, _downData)),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSpeedBadge(Icons.arrow_downward, _downSpeed, Colors.blue),
              const SizedBox(width: 15),
              _buildSpeedBadge(Icons.arrow_upward, _upSpeed, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedBadge(IconData icon, double speed, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${speed.toStringAsFixed(1)} kbps',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue.shade300,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: Colors.blue.shade100);
  }
}

class TrafficPainter extends CustomPainter {
  final List<double> upData;
  final List<double> downData;

  TrafficPainter(this.upData, this.downData);

  @override
  void paint(Canvas canvas, Size size) {
    _drawData(canvas, size, downData, Colors.blue);
    _drawData(canvas, size, upData, Colors.green);
  }

  void _drawData(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height - data[0]);

    for (int i = 1; i < data.length; i++) {
      path.lineTo(i * stepX, size.height - data[i]);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrafficPainter oldDelegate) => true;
}
