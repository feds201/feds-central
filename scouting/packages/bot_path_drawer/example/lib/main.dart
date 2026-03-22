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
  final List<String> _paths = [];
  int _selectedIndex = 0;
  bool _useCustomColors = false;

  String? get _selectedPath =>
      _paths.isNotEmpty ? _paths[_selectedIndex] : null;

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
                  setState(() {
                    _paths.add(pathData);
                    _selectedIndex = _paths.length - 1;
                  });
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
                  const SizedBox(width: 8),
                  // Custom colors toggle
                  _toggleButton(
                    selected: _useCustomColors,
                    onPressed: () =>
                        setState(() => _useCustomColors = !_useCustomColors),
                    child: const Text('Custom colors'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Draw button
              FilledButton.tonalIcon(
                onPressed: _openDrawer,
                icon: const Icon(Icons.draw, size: 18),
                label: const Text('Draw New Path'),
              ),
              const SizedBox(height: 16),

              // Path navigator or empty state
              if (_paths.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No paths saved, create one!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                )
              else ...[
                // Compact navigator: << [Path 1 of 5] >> [delete]
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonal(
                      onPressed: _selectedIndex > 0
                          ? () => setState(() => _selectedIndex--)
                          : null,
                      child: const Icon(Icons.chevron_left, size: 18),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<int>(
                      onSelected: (i) =>
                          setState(() => _selectedIndex = i),
                      itemBuilder: (_) => [
                        for (var i = 0; i < _paths.length; i++)
                          PopupMenuItem(
                            value: i,
                            child: Text('Path ${i + 1}'),
                          ),
                      ],
                      // IgnorePointer lets PopupMenuButton handle the tap
                      // while the button still looks enabled.
                      child: IgnorePointer(
                        child: FilledButton.tonal(
                          onPressed: () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Path ${_selectedIndex + 1} of ${_paths.length}',
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.tonal(
                      onPressed: _selectedIndex < _paths.length - 1
                          ? () => setState(() => _selectedIndex++)
                          : null,
                      child: const Icon(Icons.chevron_right, size: 18),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          _paths.removeAt(_selectedIndex);
                          if (_selectedIndex >= _paths.length &&
                              _paths.isNotEmpty) {
                            _selectedIndex = _paths.length - 1;
                          }
                        });
                      },
                      child: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Viewer
                Expanded(
                  child: BotPathViewer(
                    config: _configWithBrightness,
                    pathData: _selectedPath!,
                  ),
                ),
                const SizedBox(height: 8),

                // Serialized data
                Text('Serialized path data:',
                    style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedPath!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.tonal(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _selectedPath!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(Icons.copy, size: 16),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
