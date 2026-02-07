import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'components/header.dart';
import 'components/battery_indicator.dart';
import 'components/serial_display.dart';
import 'components/control_button.dart';
import 'components/shutter_button.dart';
import 'components/qr_code_overlay.dart';
import 'services/scout_ops_service.dart';
import 'models/scout_ops_data.dart';

class ScoutOpsScanner extends StatefulWidget {
  const ScoutOpsScanner({super.key});

  @override
  State<ScoutOpsScanner> createState() => _ScoutOpsScannerState();
}

class _ScoutOpsScannerState extends State<ScoutOpsScanner> {
  Barcode? _barcode;
  MobileScannerController controller = MobileScannerController();
  final ScoutOpsService _service = ScoutOpsService();
  
  @override
  void initState() {
    super.initState();
    _service.startBatterySimulation();
    
    // Ensure immersive mode is maintained
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.isNotEmpty ? barcodes.barcodes.first : null;
      });
      if (_barcode != null) {
        _service.updateLastScan(_barcode!.rawValue ?? 'Unknown');
      }
    }
  }

  void _onReset() {
    setState(() {
      _barcode = null;
    });
    _service.resetData();
  }

  void _onTest() {
    // Handle test functionality
    print('Test button pressed');
  }

  void _onShutter() {
    // Handle shutter/capture functionality
    print('Shutter pressed');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScoutOpsData>(
      stream: _service.dataStream,
      initialData: _service.currentData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _service.currentData;
        
        return Scaffold(
          backgroundColor: const Color(0xFF1C1C1C),
          extendBodyBehindAppBar: true,
          body: Column(
            children: [
              // Header
              const ScoutHeader(),
              
              // Camera feed area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Camera feed
                        MobileScanner(
                          controller: controller,
                          onDetect: _handleBarcode,
                        ),
                        
                        // QR code overlay
                        QRCodeOverlay(
                          barcode: _barcode,
                          onTap: () {
                            // Handle QR code tap
                            print('QR code tapped: ${_barcode?.rawValue}');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom control panel
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Battery indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        BatteryIndicator(
                          percentage: data.moduleBattery,
                          label: 'MODULE BATTERY',
                        ),
                        BatteryIndicator(
                          percentage: data.targetBattery,
                          label: 'TARGET BATTERY',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Serial number and control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SerialDisplay(serialNumber: data.serialNumber),
                        Row(
                          children: [
                            ControlButton(
                              text: 'RESET',
                              backgroundColor: Colors.red,
                              onPressed: _onReset,
                            ),
                            const SizedBox(width: 8),
                            ControlButton(
                              text: 'TEST',
                              backgroundColor: Colors.green,
                              onPressed: _onTest,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Shutter button
                    ShutterButton(
                      onPressed: _onShutter,
                      size: 80,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
