import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class _HopResult {
  final int hop;
  final String ip;
  final String? hostname;
  final String label;
  final int? ms;
  final bool timedOut;

  _HopResult({
    required this.hop,
    required this.ip,
    this.hostname,
    this.label = '',
    this.ms,
    this.timedOut = false,
  });
}

class TraceroutePage extends StatefulWidget {
  final String? initialTarget;
  const TraceroutePage({super.key, this.initialTarget});

  @override
  State<TraceroutePage> createState() => _TraceroutePageState();
}

class _TraceroutePageState extends State<TraceroutePage> {
  late final TextEditingController _targetController;
  final ScrollController _scrollController = ScrollController();
  bool _isTracing = false;
  final List<_HopResult> _hops = [];
  Process? _process;

  // Stats
  int _totalHops = 0;
  int _timeouts = 0;
  int? _minMs;
  int? _maxMs;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: widget.initialTarget ?? '');
    if (widget.initialTarget != null && widget.initialTarget!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTrace());
    }
  }

  Future<void> _startTrace() async {
    FocusScope.of(context).unfocus();
    final target = _targetController.text.trim();
    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Please enter a target IP or domain first.'),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTracing = true;
      _hops.clear();
      _totalHops = 0;
      _timeouts = 0;
      _minMs = null;
      _maxMs = null;
    });

    try {
      if (Platform.isWindows) {
        // Remove '-d' to allowed hostname resolution
        _process = await Process.start('tracert', [
          '-h',
          '30',
          '-w',
          '1000',
          target,
        ]);

        _process!.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen((line) {
              if (!mounted || !_isTracing) return;
              final trimmed = line.trim();
              if (trimmed.isEmpty) return;
              if (trimmed.contains('Tracing route') ||
                  trimmed.contains('over a maximum') ||
                  trimmed.contains('Trace complete')) {
                return;
              }

              // Windows tracert line format examples:
              // " 1    <1 ms    <1 ms     1 ms  wifi.wifi [192.168.4.1]"
              // " 2     5 ms     3 ms     4 ms  192.168.100.1"
              final hopRegex = RegExp(r'^\s*(\d+)\s+(.+)$');
              final match = hopRegex.firstMatch(trimmed);
              if (match != null) {
                final hopNum = int.tryParse(match.group(1)!) ?? 0;
                final rest = match.group(2)!.trim();

                final timedOut = rest.contains('* * *') || !rest.contains('ms');
                String ip = '*';
                String? hostname;
                int? ms;

                if (!timedOut) {
                  // Extract IP
                  final ipRegex = RegExp(r'\[?(\d{1,3}(?:\.\d{1,3}){3})\]?');
                  final ipMatch = ipRegex.firstMatch(rest);
                  ip = ipMatch?.group(1) ?? '*';

                  // Extract Hostname (everything after the last 'ms' or '<1 ms', before the IP brackets)
                  final namePart = rest
                      .split(RegExp(r'\d+\s*ms|<1\s*ms'))
                      .last
                      .trim();
                  if (namePart.isNotEmpty) {
                    if (namePart.contains('[') && namePart.contains(']')) {
                      hostname = namePart.split('[').first.trim();
                    } else if (namePart != ip) {
                      hostname = namePart;
                    }
                  }

                  final msMatch = RegExp(r'(\d+)\s*ms').firstMatch(rest);
                  ms = msMatch != null ? int.tryParse(msMatch.group(1)!) : null;
                }

                _addHop(
                  _HopResult(
                    hop: hopNum,
                    ip: ip,
                    hostname: (hostname == ip) ? null : hostname,
                    ms: ms,
                    timedOut: timedOut,
                  ),
                );
              }
            });
        await _process!.exitCode;
      } else {
        // Android / Linux: ping with TTL loop
        for (int ttl = 1; ttl <= 30; ttl++) {
          if (!mounted || !_isTracing) break;
          final result = await Process.run('ping', [
            '-c',
            '1',
            '-t',
            ttl.toString(),
            '-W',
            '1',
            target,
          ]);
          final out = '${result.stdout}${result.stderr}';
          final ipRegex = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b');

          if (out.contains('exceeded') || out.contains('Time to live')) {
            final matches = ipRegex.allMatches(out).toList();
            final hopIp = matches.isNotEmpty ? matches.last.group(0)! : '*';
            final msMatch = RegExp(r'time=(\d+(?:\.\d+)?)').firstMatch(out);
            final ms = msMatch != null
                ? double.tryParse(msMatch.group(1)!)?.toInt()
                : null;
            _addHop(_HopResult(hop: ttl, ip: hopIp, ms: ms, timedOut: false));
          } else if (out.contains('bytes from')) {
            final matches = ipRegex.allMatches(out).toList();
            final hopIp = matches.isNotEmpty ? matches.last.group(0)! : target;
            final msMatch = RegExp(r'time=(\d+(?:\.\d+)?)').firstMatch(out);
            final ms = msMatch != null
                ? double.tryParse(msMatch.group(1)!)?.toInt()
                : null;
            _addHop(
              _HopResult(
                hop: ttl,
                ip: hopIp,
                ms: ms,
                label: 'Destination',
                timedOut: false,
              ),
            );
            break;
          } else {
            _addHop(_HopResult(hop: ttl, ip: '*', timedOut: true));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isTracing = false);
    }
  }

  void _addHop(_HopResult hop) {
    if (!mounted) return;
    setState(() {
      _hops.add(hop);
      _totalHops = _hops.length;
      if (hop.timedOut) {
        _timeouts++;
      } else if (hop.ms != null) {
        _minMs = (_minMs == null || hop.ms! < _minMs!) ? hop.ms : _minMs;
        _maxMs = (_maxMs == null || hop.ms! > _maxMs!) ? hop.ms : _maxMs;
      }
    });
    _scrollToBottom();
  }

  void _stopTrace() {
    _process?.kill();
    setState(() => _isTracing = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    _scrollController.dispose();
    _process?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Traceroute'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopInput(),
              _buildStatsGrid(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.route, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'HOP RESULTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    if (_isTracing) ...[
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tracing...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 360, child: _buildHopList()),
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
              controller: _targetController,
              enabled: !_isTracing,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Enter IP or Domain...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                icon: Icon(Icons.route, color: Colors.white70),
              ),
              onSubmitted: (_) => _startTrace(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Example: google.com or 8.8.8.8',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final successHops = _totalHops - _timeouts;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
        children: [
          _buildStatCard('Hops', '$_totalHops', Colors.blue),
          _buildStatCard('OK', '$successHops', Colors.green),
          _buildStatCard('Timeout', '$_timeouts', Colors.red),
          _buildStatCard(
            'Min',
            _minMs != null ? '${_minMs}ms' : '--',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
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

  Widget _buildHopList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _hops.isEmpty && !_isTracing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text(
                      'No hops yet.\nEnter a target and press Trace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _hops.length,
                itemBuilder: (context, index) {
                  final hop = _hops[index];
                  final isTimeout = hop.timedOut;
                  final isDestination = hop.label.isNotEmpty;
                  final Color rowColor = isTimeout
                      ? Colors.red
                      : isDestination
                      ? Colors.green
                      : Colors.blue;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: rowColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: rowColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rowColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${hop.hop}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: rowColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTimeout ? '* * *' : (hop.hostname ?? hop.ip),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isTimeout
                                      ? Colors.red[700]
                                      : Colors.black87,
                                ),
                              ),
                              if (!isTimeout && hop.hostname != null)
                                Text(
                                  hop.ip,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (isDestination)
                                Text(
                                  '✓ Destination Reached',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (isTimeout)
                                Text(
                                  'Request timed out',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red[400],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          isTimeout
                              ? '--'
                              : (hop.ms != null ? '${hop.ms}ms' : '<1ms'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rowColor,
                            fontSize: 14,
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
          onPressed: _isTracing ? _stopTrace : _startTrace,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isTracing
                ? Colors.redAccent
                : AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            shadowColor:
                (_isTracing ? Colors.redAccent : AppConstants.primaryColor)
                    .withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isTracing ? Icons.stop : Icons.route),
              const SizedBox(width: 10),
              Text(
                _isTracing ? 'STOP TRACE' : 'START TRACEROUTE',
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
