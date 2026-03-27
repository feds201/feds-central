import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

class EventEntryScreen extends StatefulWidget {
  const EventEntryScreen({super.key});

  @override
  State<EventEntryScreen> createState() => _EventEntryScreenState();
}

class _EventEntryScreenState extends State<EventEntryScreen>
    with SingleTickerProviderStateMixin {
  final _eventKeyCtl = TextEditingController(text: '2026mimid');
  final _tableCtl = TextEditingController(text: 'scouting_data');
  final _formKey = GlobalKey<FormState>();

  String? _csvFileName;
  String? _csvContent;

  late final AnimationController _fadeCtl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);
    _fadeCtl.forward();
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    _eventKeyCtl.dispose();
    _tableCtl.dispose();
    super.dispose();
  }

  /// Pick a CSV file from the user's machine.
  void _pickCsv() {
    final input = html.FileUploadInputElement()..accept = '.csv';
    input.click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoadEnd.listen((_) {
        setState(() {
          _csvFileName = file.name;
          _csvContent = reader.result as String?;
        });
      });
    });
  }

  /// Load from CSV file.
  Future<void> _loadCsv() async {
    if (_csvContent == null) return;
    final svc = context.read<DataService>();
    svc.configure(
      eventKey: _eventKeyCtl.text.trim(),
      tableName: '',
    );

    svc.loadFromCsv(_csvContent!);

    // Also try to fetch TBA/Statbotics data.
    await svc.fetchExternalOnly();

    if (!mounted) return;
    if (svc.scoutingByTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No teams found in CSV',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          backgroundColor: AppTheme.red.withOpacity(0.85),
        ),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/compare');
    }
  }

  /// Load from Neon database.
  Future<void> _loadNeon() async {
    if (!_formKey.currentState!.validate()) return;
    final svc = context.read<DataService>();
    svc.configure(
      eventKey: _eventKeyCtl.text.trim(),
      tableName: _tableCtl.text.trim(),
    );

    await svc.fetchAll();

    if (!mounted) return;
    if (svc.error != null && svc.scoutingByTeam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            svc.error!,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: AppTheme.red.withOpacity(0.85),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/compare');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<DataService, bool>((s) => s.loading);

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Logo ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.radar_rounded,
                              color: AppTheme.accent, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Text('Scout-Ops Dash',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(color: AppTheme.text)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('FRC 201 · The Feds',
                        textAlign: TextAlign.center,
                        style: AppTheme.mono(12, color: AppTheme.muted)),
                    const SizedBox(height: 36),

                    // ── Event Key ────────────────────────────────────
                    _field(
                      controller: _eventKeyCtl,
                      label: 'Event Key',
                      hint: '2026mimid',
                      icon: Icons.event_rounded,
                      validator: _required,
                    ),
                    const SizedBox(height: 20),

                    // ── Divider: data source ─────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Load scouting data from',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Option 1: CSV Upload ─────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.upload_file_rounded,
                                    size: 18, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Text('CSV File',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // File picker row.
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceHi,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppTheme.border),
                                    ),
                                    child: Text(
                                      _csvFileName ?? 'No file selected',
                                      style: TextStyle(
                                        color: _csvFileName != null
                                            ? AppTheme.text
                                            : AppTheme.muted,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 40,
                                  child: OutlinedButton(
                                    onPressed: _pickCsv,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: AppTheme.accent
                                              .withOpacity(0.4)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                    ),
                                    child: Text('Browse',
                                        style: TextStyle(
                                            color: AppTheme.accent,
                                            fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: (loading || _csvContent == null)
                                    ? null
                                    : _loadCsv,
                                icon: loading
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.bg),
                                      )
                                    : const Icon(Icons.upload_rounded,
                                        size: 18),
                                label: const Text('Load CSV'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Option 2: Neon Database ──────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.storage_rounded,
                                    size: 18, color: AppTheme.gold),
                                const SizedBox(width: 8),
                                Text('Neon Database',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                            const SizedBox(height: 10),

                            _field(
                              controller: _tableCtl,
                              label: 'Scouting Table Name',
                              hint: 'scouting_data',
                              icon: Icons.table_chart_rounded,
                            ),
                            const SizedBox(height: 12),

                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: loading ? null : _loadNeon,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gold,
                                ),
                                icon: loading
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.bg),
                                      )
                                    : const Icon(Icons.cloud_download_rounded,
                                        size: 18),
                                label: const Text('Load from Neon'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.muted),
      ),
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
