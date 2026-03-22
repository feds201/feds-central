import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bot Path Drawer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _themeMode,
      home: DemoHome(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}

class DemoHome extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const DemoHome({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  String? _savedPath;
  bool _useCustomColors = false;

  BotPathConfig get _config {
    if (_useCustomColors) {
      return BotPathConfig(
        backgroundImage: AssetImage('assets/bg.jpg'),
        pathColor: Colors.cyan,
        robotColor: Color(0x33FF5722),
        startColor: Colors.blue,
        endColor: Colors.purple,
      );
    }
    return BotPathConfig(
      backgroundImage: const AssetImage('assets/bg.jpg'),
    );
  }

  Brightness? get _brightnessOverride {
    switch (widget.themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return null;
    }
  }

  BotPathConfig get _configWithBrightness {
    return _config.copyWith(brightness: _brightnessOverride);
  }

  void _openDrawer() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenSize = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: SizedBox(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.9,
            child: BotPathDrawer(
              config: _configWithBrightness,
              onSave: (pathData) {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _savedPath = pathData;
                });
              },
            ),
          ),
        );
      },
    );

    await SystemChrome.setPreferredOrientations([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Settings row
              Row(
                children: [
                  // Theme toggle
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                    ],
                    selected: {widget.themeMode},
                    onSelectionChanged: (s) =>
                        widget.onThemeModeChanged(s.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Custom colors toggle
                  FilterChip(
                    label: const Text('Custom colors'),
                    selected: _useCustomColors,
                    onSelected: (v) =>
                        setState(() => _useCustomColors = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Draw button
              ElevatedButton.icon(
                onPressed: _openDrawer,
                icon: const Icon(Icons.draw),
                label: const Text('Draw Path'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Serialized data text field
              Text('Serialized path data:',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxHeight: 80),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _savedPath ?? '(none)',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _savedPath != null ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Viewer (if path exists)
              if (_savedPath != null) ...[
                Text('Viewer:',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Expanded(
                  child: BotPathViewer(
                    config: _configWithBrightness,
                    pathData: _savedPath!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
