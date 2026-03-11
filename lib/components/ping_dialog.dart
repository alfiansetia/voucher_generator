import 'dart:async';
import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class PingDialog extends StatefulWidget {
  final String ip;

  const PingDialog({super.key, required this.ip});

  @override
  State<PingDialog> createState() => _PingDialogState();
}

class _PingDialogState extends State<PingDialog> {
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

    final ping = Ping(widget.ip);
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

      // Auto scroll only if user is at the bottom
      Timer(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Network Diagnostic',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Target: ${widget.ip}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.dialogRadius),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            _buildStatsHeader(),
            const SizedBox(height: 12),
            _buildAdvancedStats(),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _responses.isEmpty && !_isPinging
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 48,
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ready to Start Diagnostic',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _responses.length,
                        itemBuilder: (context, index) {
                          final res = _responses[index];
                          final isSuccess = res.time != null;
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSuccess
                                  ? Colors.green.withValues(alpha: 0.05)
                                  : Colors.red.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSuccess ? Icons.check_circle : Icons.error,
                                  color: isSuccess ? Colors.green : Colors.red,
                                  size: 14,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Seq ${res.seq}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  isSuccess
                                      ? '${res.time!.inMilliseconds} ms'
                                      : 'Timed Out',
                                  style: TextStyle(
                                    color: isSuccess
                                        ? Colors.blue[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _togglePing,
            icon: Icon(
              _isPinging ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 28,
            ),
            label: Text(
              _isPinging ? 'STOP DIAGNOSTIC' : 'START DIAGNOSTIC',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPinging
                  ? Colors.redAccent
                  : AppConstants.primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor:
                  (_isPinging ? Colors.redAccent : AppConstants.primaryColor)
                      .withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final lossPercent = _transmitted == 0
        ? 0
        : (_lost / _transmitted * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeroStat('SENT', '$_transmitted', Colors.white),
          _buildHeroStat('OK', '$_received', Colors.white),
          _buildHeroStat('LOSS', '$lossPercent%', Colors.white),
        ],
      ),
    );
  }

  Widget _buildAdvancedStats() {
    return Row(
      children: [
        _buildSmallStat('Min', _minTime != null ? '${_minTime}ms' : '--'),
        const SizedBox(width: 8),
        _buildSmallStat('Max', _maxTime != null ? '${_maxTime}ms' : '--'),
        const SizedBox(width: 8),
        _buildSmallStat(
          'Avg',
          _avgTime != null ? '${_avgTime!.toStringAsFixed(1)}ms' : '--',
        ),
      ],
    );
  }

  Widget _buildHeroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
