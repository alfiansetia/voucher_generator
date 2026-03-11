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

  // Real-time calculation helpers
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

            // Stats updates
            _minTime = (_minTime == null || ms < _minTime!) ? ms : _minTime;
            _maxTime = (_maxTime == null || ms > _maxTime!) ? ms : _maxTime;
            _avgTime = (_avgTime == null)
                ? ms.toDouble()
                : (_avgTime! * (_received - 1) + ms) / _received;
          } else {
            _lost++;
          }
        }

        if (event.summary != null) {
          _isPinging = false;
        }
      });

      // Auto scroll
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
    setState(() {
      _isPinging = false;
    });
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ping Tool'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopPing();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopInput(),
              _buildStatsGrid(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.terminal, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'LOG OUTPUT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Use a fixed height for log area to keep it scrollable and stable
              SizedBox(height: 300, child: _buildLogArea()),
              _buildActionButton(),
            ],
          ),
        ),
      ),
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
              controller: _hostController,
              enabled: !_isPinging,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Enter IP or Hostname...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                icon: Icon(Icons.language, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Example: google.com or 192.168.1.1',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No diagnostic data yet',
                      style: TextStyle(color: Colors.grey),
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
                  return Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withValues(alpha: 0.05)
                          : Colors.red.withValues(alpha: 0.05),
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
                        const Icon(
                          Icons.arrow_right_alt,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSuccess
                              ? 'Reply from ${_hostController.text}'
                              : 'Request Timeout',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSuccess ? Colors.black87 : Colors.red[700],
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

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _togglePing,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isPinging
                ? Colors.redAccent
                : AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            shadowColor:
                (_isPinging ? Colors.redAccent : AppConstants.primaryColor)
                    .withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isPinging ? Icons.stop : Icons.sensors),
              const SizedBox(width: 10),
              Text(
                _isPinging ? 'STOP DIAGNOSTIC' : 'RUN DIAGNOSTIC',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
