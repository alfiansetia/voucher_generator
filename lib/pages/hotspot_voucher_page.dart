import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/mikrotik_bloc.dart';
import '../core/constants/app_constants.dart';

class HotspotVoucherPage extends StatefulWidget {
  const HotspotVoucherPage({super.key});

  @override
  State<HotspotVoucherPage> createState() => _HotspotVoucherPageState();
}

class _HotspotVoucherPageState extends State<HotspotVoucherPage> {
  final _formKey = GlobalKey<FormState>();

  // Form values
  int _quantity = 10;
  String _selectedServer = 'all';
  String _selectedProfile = 'default';
  String _userMode = 'user_pass';
  int _userLength = 6;
  String _prefix = '';
  String _note = '';
  String _selectedCharSet = 'mixed';

  final Map<String, String> _charSets = {
    'mixed': '123456789abcdefghjkmnpqrstuvwxyz',
    'numbers': '1234567890',
    'lowercase': 'abcdefghijklmnopqrstuvwxyz',
    'uppercase': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  };

  bool _isLoading = false;
  bool _isFetchingInitialData = true;
  List<Map<String, String>> _profiles = [];
  List<Map<String, String>> _servers = [];

  @override
  void initState() {
    super.initState();
    // Gunakan delay untuk memastikan context dan build awal siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;

    try {
      debugPrint('VoucherPage: Mengambil data lewat antrian utama...');
      final repo = BlocProvider.of<MikrotikBloc>(
        context,
        listen: false,
      ).repository;

      // Gunakan antrian utama (queue) — tanpa timeout keras agar tidak crash
      // MikroTik menserialisasi request dari akun yang sama, jadi koneksi terpisah pun tetap antri
      final List<Map<String, String>> profiles = await repo
          .getHotspotProfiles();
      final List<Map<String, String>> servers = await repo.getHotspotServers();

      debugPrint(
        'VoucherPage: ${profiles.length} profiles, ${servers.length} servers',
      );

      if (mounted) {
        setState(() {
          _profiles = profiles;
          _servers = servers;

          String safeProfile = 'default';
          if (_profiles.isNotEmpty) {
            for (var p in _profiles) {
              if ((p['name'] ?? '').toLowerCase() == 'default') {
                safeProfile = p['name'] ?? 'default';
                break;
              }
            }
            if (safeProfile == 'default') {
              safeProfile = _profiles.first['name'] ?? 'default';
            }
          }

          _selectedProfile = safeProfile;
          _selectedServer = 'all';
          _isFetchingInitialData = false;
        });
        debugPrint('VoucherPage: Berhasil. Profile: $_selectedProfile');
      }
    } catch (e, stack) {
      debugPrint('VoucherPage Error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          _isFetchingInitialData = false;
          _selectedProfile = 'default';
        });
      }
    }
  }

  String _generateRandomString(int length) {
    final random = Random();
    final chars = _charSets[_selectedCharSet] ?? _charSets['mixed']!;
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _generateVouchers() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repo = context.read<MikrotikBloc>().repository;

    int createdCount = 0;
    int errorCount = 0;

    // Format Comment Baru: [prefix].[xxx].[dd].[mm].[yy]-[zzzz]
    final now = DateTime.now();
    final String modePrefix = _userMode == 'user_pass' ? 'vc' : 'up';
    final String randomPart = Random().nextInt(1000).toString().padLeft(3, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String month = now.month.toString().padLeft(2, '0');
    final String year = now.year.toString().substring(2);

    String batchComment = '$modePrefix.$randomPart.$day.$month.$year';
    if (_note.isNotEmpty) batchComment += '-$_note';

    try {
      for (int i = 0; i < _quantity; i++) {
        final username =
            (_prefix.isNotEmpty ? _prefix : '') +
            _generateRandomString(_userLength);
        final password = _userMode == 'user_pass'
            ? username
            : _generateRandomString(_userLength);

        try {
          await repo.addHotspotUser(
            name: username,
            password: password,
            profile: _selectedProfile,
            server: _selectedServer,
            comment: batchComment,
          );
          createdCount++;
        } catch (e) {
          errorCount++;
        }
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Generation Complete'),
            content: Text(
              'Successfully created $createdCount users.\nErrors: $errorCount',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Process failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Generate Vouchers'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isFetchingInitialData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Basic Configuration'),
                    const SizedBox(height: 15),
                    _buildCard(isDark, [
                      _buildSafeDropdown(
                        label: 'Hotspot Server',
                        value: _selectedServer,
                        items: _buildServerItems(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedServer = val);
                          }
                        },
                      ),
                      const Divider(height: 30),
                      _buildSafeDropdown(
                        label: 'User Profile',
                        value: _selectedProfile,
                        items: _buildProfileItems(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedProfile = val);
                          }
                        },
                      ),
                      const Divider(height: 30),
                      _buildNumberField(
                        label: 'Quantity',
                        initialValue: _quantity.toString(),
                        onChanged: (val) => _quantity = int.tryParse(val) ?? 1,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final n = int.tryParse(value);
                          if (n == null || n <= 0) return 'Must be > 0';
                          if (n > 500) return 'Max 500 at once';
                          return null;
                        },
                      ),
                      const Divider(height: 30),
                      _buildTextField(
                        label: 'Batch Note (Optional)',
                        hint: 'e.g. Promo-Merdeka',
                        onChanged: (val) => _note = val,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final regex = RegExp(r'^[a-zA-Z0-9-]+$');
                            if (!regex.hasMatch(value)) {
                              return 'Alpha-Numeric & - only';
                            }
                          }
                          return null;
                        },
                      ),
                    ]),

                    const SizedBox(height: 25),
                    _buildSectionTitle(context, 'User Format'),
                    const SizedBox(height: 15),
                    _buildCard(isDark, [
                      _buildSafeDropdown(
                        label: 'Voucher Type',
                        value: _userMode,
                        items: const [
                          DropdownMenuItem(
                            value: 'user_pass',
                            child: Text('Username = Password'),
                          ),
                          DropdownMenuItem(
                            value: 'separate',
                            child: Text('Separate User & Pass'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _userMode = val);
                        },
                      ),
                      const Divider(height: 30),
                      _buildNumberField(
                        label: 'Character Length',
                        initialValue: _userLength.toString(),
                        onChanged: (val) =>
                            _userLength = int.tryParse(val) ?? 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final n = int.tryParse(value);
                          if (n == null || n < 4 || n > 16) {
                            return 'Range: 4-16';
                          }
                          return null;
                        },
                      ),
                      const Divider(height: 30),
                      _buildTextField(
                        label: 'Prefix (Optional)',
                        hint: 'e.g. KV-',
                        onChanged: (val) => _prefix = val,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final regex = RegExp(r'^[a-zA-Z0-9-]+$');
                            if (!regex.hasMatch(value)) {
                              return 'Alpha-Numeric & - only';
                            }
                          }
                          return null;
                        },
                      ),
                      const Divider(height: 30),
                      _buildSafeDropdown(
                        label: 'Character Set',
                        value: _selectedCharSet,
                        items: const [
                          DropdownMenuItem(
                            value: 'mixed',
                            child: Text('Mixed (Alpha-Numeric)'),
                          ),
                          DropdownMenuItem(
                            value: 'numbers',
                            child: Text('Numbers Only'),
                          ),
                          DropdownMenuItem(
                            value: 'lowercase',
                            child: Text('Lowercase Only'),
                          ),
                          DropdownMenuItem(
                            value: 'uppercase',
                            child: Text('Uppercase Only'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCharSet = val);
                          }
                        },
                      ),
                    ]),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateVouchers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'GENERATE NOW',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  List<DropdownMenuItem<String>> _buildServerItems() {
    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: 'all', child: Text('all')),
    ];
    final Set<String> seen = {'all'};

    for (var s in _servers) {
      final name = s['name'];
      if (name != null && name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        items.add(DropdownMenuItem(value: name, child: Text(name)));
      }
    }
    return items;
  }

  List<DropdownMenuItem<String>> _buildProfileItems() {
    final List<DropdownMenuItem<String>> items = [];
    final Set<String> seen = {};

    for (var p in _profiles) {
      final name = p['name'];
      if (name != null && name.isNotEmpty && !seen.contains(name)) {
        seen.add(name);
        items.add(DropdownMenuItem(value: name, child: Text(name)));
      }
    }

    if (items.isEmpty) {
      items.add(
        const DropdownMenuItem(value: 'default', child: Text('default')),
      );
    }

    return items;
  }

  Widget _buildSafeDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    String safeValue = value;
    final bool exists = items.any((item) => item.value == value);
    if (!exists && items.isNotEmpty) {
      safeValue = items.first.value ?? 'default';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: safeValue,
            items: items,
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down),
            itemHeight: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white38 : Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
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
          color: isDark ? Colors.white10 : Colors.grey.shade100,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        TextFormField(
          initialValue: initialValue,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            errorStyle: TextStyle(fontSize: 10, height: 0.8),
          ),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        TextFormField(
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            errorStyle: const TextStyle(fontSize: 10, height: 0.8),
          ),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
