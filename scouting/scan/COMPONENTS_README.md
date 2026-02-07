# Scout Ops Scanner Components

This Flutter application provides a modular QR code scanner interface for Scout Ops operations. The app is designed with reusable components for easy maintenance and scalability.

## Component Structure

### Core Components

1. **ScoutHeader** (`lib/components/header.dart`)
   - App title display with modern styling
   - Status indicator (red dot)
   - Uses Orbitron font for futuristic look

2. **BatteryIndicator** (`lib/components/battery_indicator.dart`)
   - Displays battery percentage with color coding
   - Green (80%+), Yellow (50-79%), Orange (20-49%), Red (<20%)
   - Customizable label text

3. **SerialDisplay** (`lib/components/serial_display.dart`)
   - Shows device serial number
   - Styled with monospace font

4. **ControlButton** (`lib/components/control_button.dart`)
   - Reusable button component
   - Customizable colors and text
   - Used for RESET and TEST buttons

5. **ShutterButton** (`lib/components/shutter_button.dart`)
   - Circular camera shutter-style button
   - Customizable size
   - Used for capture actions

6. **QRCodeOverlay** (`lib/components/qr_code_overlay.dart`)
   - Shows detected QR code information
   - Displays code value and format
   - Tap-to-interact functionality

### Services

**ScoutOpsService** (`lib/services/scout_ops_service.dart`)
- Manages application state
- Handles battery level updates
- Processes QR code scan results
- Provides real-time data streams

### Models

**ScoutOpsData** (`lib/models/scout_ops_data.dart`)
- Data structure for scout operations
- Contains battery levels, serial number, and scan history

### Main Scanner

**ScoutOpsScanner** (`lib/scout_ops_scanner.dart`)
- Main scanner interface
- Integrates all components
- Handles camera feed and QR code detection
- Real-time data updates via streams

## Features

- **Real-time QR Code Scanning**: Uses mobile_scanner for fast detection
- **Battery Monitoring**: Displays module and target battery levels
- **Modular Design**: Easy to customize and extend
- **Responsive UI**: Works on different screen sizes
- **State Management**: Reactive UI updates via streams
- **Modern Styling**: Uses Google Fonts (Orbitron) for futuristic appearance

## Usage

The main scanner screen automatically starts when the app launches. Components are designed to be reusable:

```dart
// Using battery indicator
BatteryIndicator(
  percentage: 75,
  label: 'DEVICE BATTERY',
  color: Colors.green,
)

// Using control button
ControlButton(
  text: 'SCAN',
  backgroundColor: Colors.blue,
  onPressed: () => performScan(),
)
```

## Color Scheme

- Primary Background: `#1C1C1C` (Dark gray)
- Secondary Background: `#2C2C2C` (Medium gray)
- Text: White/White70
- Accent: Red for status indicators
- Success: Green for positive actions
- Buttons: Red for reset, Green for test

## Dependencies

- `mobile_scanner`: QR code scanning
- `google_fonts`: Typography (Orbitron font)
- `flutter/material.dart`: UI components

## File Structure

```
lib/
├── components/
│   ├── header.dart
│   ├── battery_indicator.dart
│   ├── serial_display.dart
│   ├── control_button.dart
│   ├── shutter_button.dart
│   └── qr_code_overlay.dart
├── models/
│   └── scout_ops_data.dart
├── services/
│   └── scout_ops_service.dart
├── utils/
│   └── constants.dart
├── scout_ops_scanner.dart
└── main.dart
```

This modular approach makes it easy to:
- Add new features
- Modify existing components
- Test individual components
- Maintain consistent styling
- Scale the application
