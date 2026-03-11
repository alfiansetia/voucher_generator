import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../core/constants/app_constants.dart';

class WifiScannerPage extends StatefulWidget {
  const WifiScannerPage({super.key});

  @override
  State<WifiScannerPage> createState() => _WifiScannerPageState();
}

class _WifiScannerPageState extends State<WifiScannerPage> {
  bool _isScanning = false;
  List<WiFiAccessPoint> _accessPoints = [];
  String _statusMessage = 'Press Scan to discover nearby WiFi networks.';

  _SortMode _sortMode = _SortMode.signal;
  _BandType _bandView = _BandType.twoPointFour;

  Future<void> _startScan() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      setState(
        () => _statusMessage =
            'WiFi scanning is only supported on Android & iOS.',
      );
      return;
    }

    final locationStatus = await Permission.locationWhenInUse.request();
    if (!locationStatus.isGranted) {
      if (!mounted) return;
      setState(
        () => _statusMessage =
            'Location permission is required to scan WiFi networks.',
      );
      _showPermissionDialog();
      return;
    }
    if (Platform.isAndroid) {
      await Permission.nearbyWifiDevices.request();
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for nearby WiFi networks...';
      _accessPoints = [];
    });

    try {
      final canScan = await WiFiScan.instance.canStartScan(
        askPermissions: true,
      );
      if (canScan != CanStartScan.yes) {
        setState(() {
          _statusMessage =
              'Cannot start WiFi scan: ${canScan.name}. Make sure WiFi and Location are enabled.';
          _isScanning = false;
        });
        return;
      }

      await WiFiScan.instance.startScan();
      final canGetResults = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );
      if (canGetResults != CanGetScannedResults.yes) {
        setState(() {
          _statusMessage = 'Cannot read scan results: ${canGetResults.name}';
          _isScanning = false;
        });
        return;
      }

      final results = await WiFiScan.instance.getScannedResults();
      if (!mounted) return;

      List<WiFiAccessPoint> sorted = List.from(results);
      _applySorting(sorted);

      setState(() {
        _accessPoints = sorted;
        _isScanning = false;
        _statusMessage = 'Found ${results.length} network(s) nearby.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error during scan: $e';
        _isScanning = false;
      });
    }
  }

  void _applySorting(List<WiFiAccessPoint> list) {
    if (_sortMode == _SortMode.signal) {
      list.sort((a, b) => b.level.compareTo(a.level));
    } else {
      list.sort((a, b) => (a.ssid).compareTo(b.ssid));
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This tool requires Location permission to scan WiFi networks. Please grant it in App Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Color _signalColor(int level) {
    if (level >= -50) return Colors.green;
    if (level >= -70) return Colors.orange;
    return Colors.red;
  }

  IconData _signalIcon(int level) {
    if (level >= -50) return Icons.signal_wifi_4_bar;
    if (level >= -70) return Icons.network_wifi_3_bar;
    return Icons.signal_wifi_bad;
  }

  String _securityLabel(WiFiAccessPoint ap) {
    final cap = ap.capabilities.toUpperCase();
    if (cap.contains('WPA3')) return 'WPA3';
    if (cap.contains('WPA2')) return 'WPA2';
    if (cap.contains('WPA')) return 'WPA';
    if (cap.contains('WEP')) return 'WEP';
    return 'OPEN';
  }

  Color _securityColor(String label) {
    switch (label) {
      case 'WPA3':
        return Colors.green;
      case 'WPA2':
        return Colors.blue;
      case 'WPA':
        return Colors.orange;
      case 'WEP':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _levelToPercent(int level) {
    if (level <= -100) return 0;
    if (level >= -50) return 100;
    return 2 * (level + 100);
  }

  String _frequencyToChannel(int freq) {
    if (freq <= 0) return '?';
    if (freq >= 2412 && freq <= 2484) {
      if (freq == 2484) return '14';
      return '${(freq - 2412) ~/ 5 + 1}';
    }
    if (freq >= 5170 && freq <= 5905) return '${(freq - 5000) ~/ 5}';
    if (freq >= 5955 && freq <= 7115) return '${(freq - 5950) ~/ 5}';
    return '?';
  }

  Widget _buildBandToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _bandButton('2.4 GHz', _BandType.twoPointFour),
          const SizedBox(width: 8),
          _bandButton('5 GHz', _BandType.five),
          const SizedBox(width: 8),
          _bandButton('6 GHz', _BandType.six),
        ],
      ),
    );
  }

  Widget _bandButton(String label, _BandType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _bandView == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _bandView = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color.fromARGB(255, 20, 25, 34)
                  : (isDark ? Colors.white10 : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelChart() {
    final filtered = _accessPoints.where((ap) {
      if (_bandView == _BandType.twoPointFour) {
        return ap.frequency >= 2400 && ap.frequency < 2500;
      } else if (_bandView == _BandType.five) {
        return ap.frequency >= 5000 && ap.frequency < 5950;
      } else {
        return ap.frequency >= 5950;
      }
    }).toList();

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _WifiCurvePainter(
              accessPoints: filtered,
              bandType: _bandView,
            ),
          ),
          if (filtered.isEmpty)
            const Center(
              child: Text(
                'No networks in this band',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              _bandView == _BandType.six
                  ? '6GHz'
                  : (_bandView == _BandType.five ? '5GHz' : '2.4GHz'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.1),
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('WiFi Scanner'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort by',
            onSelected: (mode) {
              setState(() {
                _sortMode = mode;
                _applySorting(_accessPoints);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SortMode.signal,
                child: ListTile(
                  leading: Icon(Icons.signal_wifi_4_bar),
                  title: Text('Sort by Signal'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: _SortMode.name,
                child: ListTile(
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text('Sort by Name'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppConstants.primaryColor,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.wifi_find,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isScanning) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ],
              ),
            ),
            if (_accessPoints.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      '${_accessPoints.length}',
                      'Total',
                      Colors.blue,
                      Icons.wifi,
                    ),
                    _buildStatChip(
                      '${_accessPoints.where((ap) => _levelToPercent(ap.level) >= 60).length}',
                      'Strong',
                      Colors.green,
                      Icons.signal_wifi_4_bar,
                    ),
                    _buildStatChip(
                      '${_accessPoints.where((ap) => _securityLabel(ap) == 'OPEN').length}',
                      'Open',
                      Colors.red,
                      Icons.lock_open,
                    ),
                  ],
                ),
              ),
            if (_accessPoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildBandToggle(),
              _buildChannelChart(),
            ],
            Expanded(
              child: _accessPoints.isEmpty && !_isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 64,
                            color: isDark ? Colors.white10 : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No networks found.\nPress Scan to start.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[500],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _accessPoints.length,
                      itemBuilder: (context, index) {
                        final ap = _accessPoints[index];
                        final level = ap.level;
                        final percent = _levelToPercent(level);
                        final secLabel = _securityLabel(ap);
                        final sigColor = _signalColor(level);

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200,
                            ),
                          ),
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: sigColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _signalIcon(level),
                                    color: sigColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ap.ssid.isNotEmpty
                                            ? ap.ssid
                                            : '(Hidden Network)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: ap.ssid.isNotEmpty
                                              ? (isDark
                                                    ? Colors.white
                                                    : Colors.black87)
                                              : Colors.grey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ap.bssid,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: LinearProgressIndicator(
                                          value: percent / 100,
                                          backgroundColor: isDark
                                              ? Colors.white10
                                              : Colors.grey[200],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                sigColor,
                                              ),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _securityColor(
                                          secLabel,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        secLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _securityColor(secLabel),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$level dBm',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: sigColor,
                                      ),
                                    ),
                                    if (ap.frequency > 0) ...[
                                      Text(
                                        ap.frequency >= 5950
                                            ? '6 GHz'
                                            : ap.frequency >= 5000
                                            ? '5 GHz'
                                            : '2.4 GHz',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'Ch ${_frequencyToChannel(ap.frequency)}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
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
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : AppConstants.primaryColor,
        icon: _isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.wifi_find, color: Colors.white),
        label: Text(
          _isScanning ? 'Scanning...' : 'SCAN WIFI',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

enum _BandType { twoPointFour, five, six }

enum _SortMode { signal, name }

class _WifiCurvePainter extends CustomPainter {
  final List<WiFiAccessPoint> accessPoints;
  final _BandType bandType;

  _WifiCurvePainter({required this.accessPoints, required this.bandType});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height - 20;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, -20, width, height + 40));

    double minCh, maxCh;
    List<int> gridChannels;

    if (bandType == _BandType.twoPointFour) {
      minCh = 0;
      maxCh = 14;
      gridChannels = [1, 6, 11];
    } else if (bandType == _BandType.five) {
      minCh = 30;
      maxCh = 170;
      gridChannels = [36, 48, 60, 100, 120, 149, 161];
    } else {
      minCh = 0;
      maxCh = 235;
      gridChannels = [1, 50, 100, 150, 200];
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var ch in gridChannels) {
      double x = (ch - minCh) / (maxCh - minCh) * width;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
      textPainter.text = TextSpan(
        text: 'Ch $ch',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, height + 4));
    }

    for (var ap in accessPoints) {
      int ch = _getChannel(ap.frequency);
      if (ch == 0) continue;

      double xCenter = (ch - minCh) / (maxCh - minCh) * width;
      double levelNormalized = ((ap.level + 100) / 70).clamp(0.0, 1.0);
      double h = math.max(10.0, levelNormalized * (height - 30));
      double wUnits = (bandType == _BandType.twoPointFour ? 2.2 : 2.0);
      double w = (wUnits / (maxCh - minCh)) * width;

      final Color color = _getAPColor(ap.bssid);
      final Path path = Path();
      path.moveTo(xCenter - w, height);
      path.quadraticBezierTo(xCenter, height - h * 2, xCenter + w, height);

      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.5),
              color.withValues(alpha: 0.01),
            ],
          ).createShader(Rect.fromLTWH(xCenter - w, height - h, w * 2, h))
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      if (ap.ssid.isNotEmpty) {
        textPainter.text = TextSpan(
          text: ap.ssid,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(xCenter - textPainter.width / 2, height - h - 14),
        );
      }
    }
    canvas.restore();
  }

  int _getChannel(int freq) {
    if (freq >= 2412 && freq <= 2484) {
      return freq == 2484 ? 14 : (freq - 2412) ~/ 5 + 1;
    }
    if (freq >= 5170 && freq <= 5825) return (freq - 5000) ~/ 5;
    if (freq >= 5955 && freq <= 7115) return (freq - 5950) ~/ 5;
    return 0;
  }

  Color _getAPColor(String bssid) {
    const List<Color> palette = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.yellowAccent,
      Colors.tealAccent,
      Colors.redAccent,
    ];
    int hash = 0;
    for (int i = 0; i < bssid.length; i++) {
      hash = bssid.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return palette[hash.abs() % palette.length];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
