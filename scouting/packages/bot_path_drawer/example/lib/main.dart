import 'package:bot_path_drawer/bot_path_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _lightBg = Color(0xFFEFE8F0);
const _darkBg = Color(0xFF312F34);
const _lightBtnTonal = Color(0xFFE0D8E2);
const _lightBtnTonalFg = Color(0xFF303030);
const _lightBtnActive = Color(0xFFD0C8D2);
const _lightBtnActiveFg = Color(0xFF1A1A1A);
const _darkBtnTonal = Color(0xFF3D3B40);
const _darkBtnTonalFg = Color(0xFFE0E0E0);
const _darkBtnActive = Color(0xFF4A474F);
const _darkBtnActiveFg = Color(0xFFFFFFFF);

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

  // Single button style for the entire app — applied via theme.
  static final _buttonStyle = FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? const ColorScheme.dark(
            surface: _darkBg,
            secondaryContainer: _darkBtnTonal,
            onSecondaryContainer: _darkBtnTonalFg,
            primary: _darkBtnActive,
            onPrimary: _darkBtnActiveFg,
          )
        : const ColorScheme.light(
            surface: _lightBg,
            secondaryContainer: _lightBtnTonal,
            onSecondaryContainer: _lightBtnTonalFg,
            primary: _lightBtnActive,
            onPrimary: _lightBtnActiveFg,
          );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bot Path Drawer Demo',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
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
  /// Mutable team data: team label -> {path name -> path data}.
  late Map<String, Map<String, String>> _teams;

  /// Text controllers for the draw dialog.
  final _pathNameController = TextEditingController(text: 'Sample');
  final _teamNameController = TextEditingController(text: '201');

  BotPathConfig get _config {
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

  @override
  void initState() {
    super.initState();
    _teams = {};
  }

  @override
  void dispose() {
    _pathNameController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  Map<String, TeamPaths> get _teamPaths {
    return {
      for (final entry in _teams.entries)
        entry.key: TeamPaths(paths: entry.value),
    };
  }

  void _openDrawer() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
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
                if (pathData != null) {
                  final teamName = _teamNameController.text.trim();
                  final pathName = _pathNameController.text.trim();
                  if (teamName.isNotEmpty && pathName.isNotEmpty) {
                    setState(() {
                      _teams.putIfAbsent(teamName, () => {});
                      // Ensure unique name within team
                      var name = pathName;
                      var counter = 2;
                      while (_teams[teamName]!.containsKey(name)) {
                        name = '$pathName $counter';
                        counter++;
                      }
                      _teams[teamName]![name] = pathData;
                    });
                  }
                }
              },
            ),
          ),
        );
      },
    );

    await SystemChrome.setPreferredOrientations([]);
  }

  /// Selected = FilledButton (primary color), unselected = FilledButton.tonal
  /// (subtle dark background). Same shape/padding via theme.
  Widget _toggleButton({
    required bool selected,
    required VoidCallback onPressed,
    required Widget child,
  }) {
    if (selected) {
      return FilledButton(onPressed: onPressed, child: child);
    }
    return FilledButton.tonal(onPressed: onPressed, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Settings row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme toggle
                  _toggleButton(
                    selected: widget.themeMode == ThemeMode.system,
                    onPressed: () =>
                        widget.onThemeModeChanged(ThemeMode.system),
                    child: const Icon(Icons.brightness_auto, size: 18),
                  ),
                  const SizedBox(width: 4),
                  _toggleButton(
                    selected: widget.themeMode == ThemeMode.light,
                    onPressed: () =>
                        widget.onThemeModeChanged(ThemeMode.light),
                    child: const Icon(Icons.light_mode, size: 18),
                  ),
                  const SizedBox(width: 4),
                  _toggleButton(
                    selected: widget.themeMode == ThemeMode.dark,
                    onPressed: () =>
                        widget.onThemeModeChanged(ThemeMode.dark),
                    child: const Icon(Icons.dark_mode, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Draw controls row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Path name field
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _pathNameController,
                      decoration: const InputDecoration(
                        labelText: 'Path name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Team name field
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _teamNameController,
                      decoration: const InputDecoration(
                        labelText: 'Team',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _openDrawer,
                    icon: const Icon(Icons.draw, size: 18),
                    label: const Text('Draw'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      setState(() => _teams.clear());
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Strategy viewer
              if (_teams.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No paths saved, draw one!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: BotPathViewerWithSelector(
                    config: _configWithBrightness.copyWith(cropFraction: 1.0),
                    teams: _teamPaths,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
