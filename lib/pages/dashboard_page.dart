import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/mikrotik_bloc.dart';
import '../bloc/mikrotik_event.dart';
import '../bloc/mikrotik_state.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/mikrotik_utils.dart';
import 'home_page.dart';
import 'hotspot_voucher_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _statsTimer;
  Timer? _tickTimer;
  Duration? _currentUptime;
  bool _isPaused = false; // Menghentikan fetch saat halaman lain sedang aktif

  @override
  void initState() {
    super.initState();
    // Start periodic timer to fetch resources every 5 seconds
    _statsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isPaused) {
        context.read<MikrotikBloc>().add(FetchMikrotikResources());
      }
    });

    // Start local tick timer for "fake realtime" every 1 second
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _currentUptime != null) {
        setState(() {
          _currentUptime = _currentUptime! + const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<MikrotikBloc, MikrotikState>(
      listener: (context, state) {
        if (state is MikrotikDisconnected) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else if (state is MikrotikConnected && state.resources != null) {
          // Sync local uptime with server data
          final uptimeStr = state.resources!['uptime'];
          if (uptimeStr != null) {
            setState(() {
              _currentUptime = MikrotikUtils.parseDuration(uptimeStr);
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false, // Remove back button
          actions: [_buildConnectionStatus(context)],
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'System Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildLiveIndicator(),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () {
                      context.read<MikrotikBloc>().add(
                        FetchMikrotikResources(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildStatisticsGrid(context),
              const SizedBox(height: 20),
              const Text(
                'Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildFeatureCard(
                      context,
                      'Voucher Generator',
                      Icons.confirmation_number,
                      Colors.orange,
                      () async {
                        final state = context.read<MikrotikBloc>().state;
                        if (state is MikrotikConnected) {
                          // Jeda timer agar tidak tabrakan dengan perintah di VoucherPage
                          setState(() => _isPaused = true);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HotspotVoucherPage(),
                            ),
                          );
                          // Timer aktif kembali setelah kembali ke Dashboard
                          if (mounted) setState(() => _isPaused = false);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not connected to MikroTik'),
                            ),
                          );
                        }
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'User Profiles',
                      Icons.person_outline,
                      Colors.blue,
                      () {
                        // Navigate to Profiles Page
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Active Users',
                      Icons.people,
                      Colors.green,
                      () {
                        // Navigate to Active Users Page
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'System Log',
                      Icons.list_alt,
                      Colors.grey,
                      () {
                        // Navigate to Logs Page
                      },
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

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return BlocBuilder<MikrotikBloc, MikrotikState>(
      builder: (context, state) {
        bool isConnected = state is MikrotikConnected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              InkWell(
                onTap: isConnected
                    ? () => _showRouterDetail(context, state.router)
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isConnected
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isConnected)
                              BoxShadow(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? 'Connected' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isConnected)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<MikrotikBloc>().add(DisconnectMikrotik());
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRouterDetail(BuildContext context, dynamic router) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.dialogRadius),
        ),
        title: Row(
          children: [
            const Icon(Icons.router, color: AppConstants.primaryColor),
            const SizedBox(width: 10),
            const Text('Router Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', router.name),
            _buildDetailRow('IP Address', router.ip),
            _buildDetailRow('Username', router.username),
            _buildDetailRow('Port', router.port.toString()),
            const Divider(height: 30),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<MikrotikBloc>().add(DisconnectMikrotik());
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Disconnect',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    return BlocBuilder<MikrotikBloc, MikrotikState>(
      builder: (context, state) {
        // Use previous resources if the current state doesn't have them yet to avoid flicker
        final resources = (state is MikrotikConnected) ? state.resources : null;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            _buildStatTile(
              'Uptime',
              _currentUptime != null
                  ? MikrotikUtils.formatDuration(_currentUptime!)
                  : '--',
              Icons.timer_outlined,
              Colors.blue,
              isLoading: _currentUptime == null,
            ),
            _buildStatTile(
              'CPU Load',
              resources != null
                  ? '${resources['cpu-load'] ?? resources['cpu_load'] ?? '--'}%'
                  : '--',
              Icons.speed,
              Colors.orange,
              isLoading: resources == null,
            ),
            _buildStatTile(
              'Free Memory',
              resources != null
                  ? '${(int.tryParse(resources['free-memory'] ?? resources['free_memory'] ?? '0') ?? 0) ~/ 1024 ~/ 1024} MB'
                  : '--',
              Icons.memory,
              Colors.green,
              isLoading: resources == null,
            ),
            _buildStatTile(
              'Board',
              resources?['board-name'] ?? resources?['board_name'] ?? '--',
              Icons.developer_board,
              Colors.purple,
              isLoading: resources == null,
            ),
            _buildStatTile(
              'Hotspot Users',
              resources != null
                  ? '${resources['hotspot-users-total']} (${resources['hotspot-users-active']} Active)'
                  : '--',
              Icons.wifi,
              Colors.red,
              isLoading: resources == null,
            ),
            _buildStatTile(
              'PPP Users',
              resources != null
                  ? '${resources['ppp-secrets-total']} (${resources['ppp-active-total']} Active)'
                  : '--',
              Icons.key_outlined,
              Colors.teal,
              isLoading: resources == null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                isLoading
                    ? SizedBox(
                        height: 14,
                        width: 40,
                        child: LinearProgressIndicator(
                          backgroundColor: color.withValues(alpha: 0.1),
                          color: color.withValues(alpha: 0.3),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
