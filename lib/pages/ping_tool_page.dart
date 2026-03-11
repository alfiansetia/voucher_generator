import 'dart:async';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'home_page.dart';

class PingToolPage extends StatefulWidget {
  const PingToolPage({super.key});

  @override
  State<PingToolPage> createState() => _PingToolPageState();
}

class _PingToolPageState extends State<PingToolPage> {
  final TextEditingController _hostController = TextEditingController(
    text: '8.8.8.8',
  );
  final List<PingResponse> _responses = [];
  StreamSubscription? _subscription;
  final ScrollController _scrollController = ScrollController();
  bool _isPinging = false;

  int _transmitted = 0;
  int _received = 0;
  int _lost = 0;
  int? _minTime;
  int? _maxTime;
  double? _avgTime;

  void _togglePing() {
    if (_isPinging) {
      _stopPing();
    } else {
      _startPing();
    }
  }

  void _startPing() {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP or Host')),
      );
      return;
    }

    setState(() {
      _responses.clear();
      _transmitted = 0;
      _received = 0;
      _lost = 0;
      _minTime = null;
      _maxTime = null;
      _avgTime = null;
      _isPinging = true;
    });

    final ping = Ping(host);
    _subscription = ping.stream.listen((event) {
      if (!mounted) return;
      setState(() {
        if (event.response != null) {
          final res = event.response!;
          _responses.add(res);
          _transmitted++;
          if (res.time != null) {
            _received++;
            final ms = res.time!.inMilliseconds;
            _minTime = (_minTime == null || ms < _minTime!) ? ms : _minTime;
            _maxTime = (_maxTime == null || ms > _maxTime!) ? ms : _maxTime;
            _avgTime = (_avgTime == null)
                ? ms.toDouble()
                : (_avgTime! * (_received - 1) + ms) / _received;
          } else {
            _lost++;
          }
        }
        if (event.summary != null) _isPinging = false;
      });
      Timer(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _stopPing() {
    _subscription?.cancel();
    setState(() => _isPinging = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hostController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ping Tool'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomePage()),
            (route) => false,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTopInput(),
          _buildStatsGrid(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'TERMINAL OUTPUT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildLogArea()),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _togglePing,
        backgroundColor: _isPinging
            ? Colors.redAccent
            : AppConstants.primaryColor,
        icon: Icon(
          _isPinging ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
        ),
        label: Text(
          _isPinging ? 'STOP' : 'START PING',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: TextField(
          controller: _hostController,
          enabled: !_isPinging,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'IP or Domain...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            icon: Icon(Icons.sensors, color: Colors.white70),
          ),
          onSubmitted: (_) => _startPing(),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final lossPercent = _transmitted == 0
        ? 0
        : (_lost / _transmitted * 100).toInt();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard('Sent', '$_transmitted', Colors.blue),
          _buildStatCard('Received', '$_received', Colors.green),
          _buildStatCard('Loss', '$lossPercent%', Colors.red),
          _buildStatCard(
            'Min',
            _minTime != null ? '${_minTime}ms' : '--',
            Colors.orange,
          ),
          _buildStatCard(
            'Max',
            _maxTime != null ? '${_maxTime}ms' : '--',
            Colors.deepOrange,
          ),
          _buildStatCard(
            'Avg',
            _avgTime != null ? '${_avgTime!.toStringAsFixed(1)}ms' : '--',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _responses.isEmpty && !_isPinging
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_tethering,
                      size: 48,
                      color: isDark ? Colors.white10 : Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No diagnostic data yet',
                      style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _responses.length,
                itemBuilder: (context, index) {
                  final res = _responses[index];
                  final isSuccess = res.time != null;
                  final Color rowColor = isSuccess ? Colors.green : Colors.red;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rowColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${res.seq}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isSuccess
                              ? 'Reply from ${_hostController.text}'
                              : 'Request Timeout',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSuccess
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.red[700],
                            fontWeight: isSuccess
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isSuccess ? '${res.time!.inMilliseconds}ms' : '--',
                          style: TextStyle(
                            color: isSuccess
                                ? Colors.blue[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
