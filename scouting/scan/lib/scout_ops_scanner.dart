import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'services/scout_ops_service.dart';
import 'models/scout_ops_data.dart';
import 'screens/neon_settings_screen.dart';

class ScoutOpsScanner extends StatefulWidget {
  const ScoutOpsScanner({super.key});

  @override
  State<ScoutOpsScanner> createState() => _ScoutOpsScannerState();
}

class _ScoutOpsScannerState extends State<ScoutOpsScanner>
    with TickerProviderStateMixin {
  MobileScannerController controller = MobileScannerController();
  final ScoutOpsService _service = ScoutOpsService();
  bool _showScanSuccess = false;
  late AnimationController _successController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _service.startBatterySimulation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (!mounted) return;
    final barcode =
        barcodes.barcodes.isNotEmpty ? barcodes.barcodes.first : null;
    if (barcode == null) return;
    setState(() {
      _showScanSuccess = true;
    });
    _service.updateLastScan(
      barcode.rawValue ?? 'Unknown',
      rawBytes: barcode.rawBytes,
    );
    _successController.forward(from: 0).then((_) {
      if (mounted) setState(() => _showScanSuccess = false);
    });
    HapticFeedback.mediumImpact();
  }

  void _onReset() {
    _service.resetData();
  }

  void _onExport() async {
    await _service.exportData();
  }

  void _onSync() async {
    final result = await _service.syncToNeon();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showHistory(ScoutOpsData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16162A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) =>
            _buildHistorySheet(data, scrollController),
      ),
    );
  }

  Widget _buildHistorySheet(
      ScoutOpsData data, ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Scan History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${data.scannedRecords.length} scans',
                style: TextStyle(color: Colors.white.withOpacity(0.4)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: data.scannedRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 48, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Text('No scans yet',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: data.scannedRecords.length,
                    itemBuilder: (context, index) {
                      final record = data.scannedRecords[
                          data.scannedRecords.length - 1 - index];
                      final cols = record.split(',');
                      final matchNum = cols.length > 7 ? cols[7].trim() : '?';
                      final alliance = cols.length > 4 ? cols[4].trim() : '';
                      final station = cols.length > 6 ? cols[6].trim() : '';
                      final isRed = alliance.toLowerCase().contains('red');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isRed
                                        ? Colors.redAccent
                                        : Colors.blueAccent)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  matchNum,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isRed
                                        ? Colors.redAccent
                                        : Colors.blueAccent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Match $matchNum',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$alliance Station $station',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle,
                                color: Color(0xFF00E676), size: 20),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScoutOpsData>(
      stream: _service.dataStream,
      initialData: _service.currentData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _service.currentData;
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full screen camera
              Positioned.fill(
                child: MobileScanner(
                  controller: controller,
                  onDetect: _handleBarcode,
                ),
              ),

              // Dim overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ),

              // Viewfinder with animated scan line
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: _ViewfinderPainter(
                          color: theme.colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _scanLineController,
                        builder: (context, child) {
                          return Positioned(
                            top: _scanLineController.value * 250 + 5,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Scan success flash
              if (_showScanSuccess)
                AnimatedBuilder(
                  animation: _successController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: theme.colorScheme.tertiary.withOpacity(
                              (1 - _successController.value) * 0.12),
                        ),
                      ),
                    );
                  },
                ),

              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(data, theme),
              ),

              // Match info card (only when data available)
              if (data.currentMatchNumber != null)
                Positioned(
                  bottom: 115,
                  left: 20,
                  right: 20,
                  child: _buildMatchCard(data, theme),
                ),

              // Bottom action bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(data, theme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(ScoutOpsData data, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Brand pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'SCOUT-UP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    ' SCAN',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Battery pill
            _pillBadge(
              icon: _getBatteryIcon(data.moduleBattery),
              iconColor: _getBatteryColor(data.moduleBattery),
              text: '${data.moduleBattery}%',
              textColor: _getBatteryColor(data.moduleBattery),
            ),

            const SizedBox(width: 8),

            // Scan count badge
            GestureDetector(
              onTap: () => _showHistory(data),
              child: _pillBadge(
                icon: Icons.qr_code_scanner,
                iconColor: Colors.white70,
                text: '${data.scannedRecords.length}',
                textColor: Colors.white,
                highlighted: data.scannedRecords.isNotEmpty,
                highlightColor: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(width: 8),

            // Settings
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NeonSettingsScreen(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08), width: 1),
                ),
                child: Icon(Icons.settings_rounded,
                    color: Colors.white.withOpacity(0.5), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillBadge({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    bool highlighted = false,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? (highlightColor ?? Colors.white).withOpacity(0.2)
            : Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(ScoutOpsData data, ThemeData theme) {
    final isRed = (data.currentAlliance ?? '').toLowerCase().contains('red');
    final allianceColor = isRed ? Colors.redAccent : Colors.blueAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xEE111122),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: allianceColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: allianceColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Match ${data.currentMatchNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.currentAlliance ?? ""} · Station ${data.currentStation ?? ""}',
                  style: TextStyle(
                    fontSize: 13,
                    color: allianceColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildStationDots(data.filledStationsForCurrentMatch),
        ],
      ),
    );
  }

  Widget _buildStationDots(Set<String> filled) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stationDot('1', Colors.redAccent, filled.contains('Red 1')),
        _stationDot('2', Colors.redAccent, filled.contains('Red 2')),
        _stationDot('3', Colors.redAccent, filled.contains('Red 3')),
        const SizedBox(width: 4),
        _stationDot('1', Colors.blueAccent, filled.contains('Blue 1')),
        _stationDot('2', Colors.blueAccent, filled.contains('Blue 2')),
        _stationDot('3', Colors.blueAccent, filled.contains('Blue 3')),
      ],
    );
  }

  Widget _stationDot(String label, Color color, bool filled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border:
            Border.all(color: color.withOpacity(filled ? 1 : 0.4), width: 1.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: filled ? Colors.white : color.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ScoutOpsData data, ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.85),
            Colors.black.withOpacity(0.95),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            color: theme.colorScheme.error,
            onTap: _onReset,
          ),
          _actionButton(
            icon: Icons.cloud_upload_rounded,
            label: 'Sync',
            color: theme.colorScheme.tertiary,
            onTap: _onSync,
          ),
          _actionButton(
            icon: Icons.ios_share_rounded,
            label: 'Export',
            color: theme.colorScheme.primary,
            onTap: _onExport,
          ),
          _actionButton(
            icon: Icons.history_rounded,
            label: 'History',
            color: theme.colorScheme.secondary,
            onTap: () => _showHistory(data),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon(int percentage) {
    if (percentage >= 80) return Icons.battery_full;
    if (percentage >= 60) return Icons.battery_5_bar;
    if (percentage >= 40) return Icons.battery_3_bar;
    if (percentage >= 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int percentage) {
    if (percentage >= 60) return const Color(0xFF00E676);
    if (percentage >= 30) return Colors.orangeAccent;
    return const Color(0xFFFF5252);
  }

  @override
  void dispose() {
    controller.dispose();
    _successController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  _ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 35.0;
    const r = 14.0;

    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len, 0),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, 0)
        ..lineTo(size.width - r, 0)
        ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
        ..lineTo(size.width, len),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - len)
        ..lineTo(0, size.height - r)
        ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
        ..lineTo(len, size.height),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - len, size.height)
        ..lineTo(size.width - r, size.height)
        ..arcToPoint(Offset(size.width, size.height - r),
            radius: const Radius.circular(r))
        ..lineTo(size.width, size.height - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
