import 'package:flutter/material.dart';
import '../services/neon_config.dart';
import '../services/neon_database.dart';

class NeonSettingsScreen extends StatefulWidget {
  const NeonSettingsScreen({super.key});

  @override
  State<NeonSettingsScreen> createState() => _NeonSettingsScreenState();
}

class _NeonSettingsScreenState extends State<NeonSettingsScreen> {
  final _connStringController = TextEditingController();
  final _tableController = TextEditingController();
  bool _loading = true;
  bool _testing = false;
  bool? _testResult;
  NeonConfig? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await NeonConfig.getInstance();
    _config = config;
    if (config.isConfigured) {
      _connStringController.text =
          'postgresql://${config.username}:****@${config.host}/${config.database}?sslmode=require&channel_binding=require';
    }
    _tableController.text = config.tableName;
    setState(() => _loading = false);
  }

  Future<void> _saveAndTest() async {
    if (_config == null) return;

    final connString = _connStringController.text.trim();
    if (connString.isEmpty) return;

    // Only parse if it looks like a new connection string (not the masked one)
    if (!connString.contains('****')) {
      _config!.parseConnectionString(connString);
    }

    final table = _tableController.text.trim();
    if (table.isNotEmpty) {
      _config!.tableName = table;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final db = NeonDatabase(_config!);
      final ok = await db.testConnection();
      if (ok) {
        await db.ensureTable();
      }
      setState(() {
        _testResult = ok;
        _testing = false;
      });
    } catch (_) {
      setState(() {
        _testResult = false;
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Database Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  _buildStatusCard(theme),
                  const SizedBox(height: 28),

                  // Connection string
                  Text(
                    'CONNECTION STRING',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _connStringController,
                    hint:
                        'postgresql://user:pass@ep-xxx.neon.tech/neondb?sslmode=require',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste the full connection string from your Neon dashboard',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Table name
                  Text(
                    'TABLE NAME',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _tableController,
                    hint: 'scouting_data',
                  ),

                  const SizedBox(height: 32),

                  // Save & Test button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _testing ? null : _saveAndTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _testing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save & Test Connection',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),

                  // Test result
                  if (_testResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (_testResult!
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF5252))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_testResult!
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFFF5252))
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testResult!
                                ? Icons.check_circle_rounded
                                : Icons.error_rounded,
                            color: _testResult!
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF5252),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _testResult!
                                  ? 'Connected! Table "${_config!.tableName}" is ready.'
                                  : 'Connection failed. Check your connection string.',
                              style: TextStyle(
                                color: _testResult!
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFF5252),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // How to get your connection string
                  _buildHelpSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final configured = _config?.isConfigured ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: configured
              ? const Color(0xFF00E676).withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (configured
                      ? const Color(0xFF00E676)
                      : theme.colorScheme.primary)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              configured ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: configured
                  ? const Color(0xFF00E676)
                  : theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  configured ? 'Neon Connected' : 'Not Connected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  configured
                      ? '${_config!.host} / ${_config!.database}'
                      : 'Add your connection string below',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF16162A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildHelpSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: Colors.white.withOpacity(0.4), size: 18),
              const SizedBox(width: 8),
              Text(
                'How to get your connection string',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _helpStep('1', 'Go to neon.tech and sign in'),
          _helpStep('2', 'Create or select a project'),
          _helpStep('3', 'Click "Connection Details" on your dashboard'),
          _helpStep(
              '4', 'Copy the connection string (starts with postgresql://)'),
          _helpStep('5', 'Paste it above and tap Save & Test'),
        ],
      ),
    );
  }

  Widget _helpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connStringController.dispose();
    _tableController.dispose();
    super.dispose();
  }
}
