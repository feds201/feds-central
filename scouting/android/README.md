# 🚀 Scout-Ops-Android

scouting_app is a mobile-friendly and UI-friendly scouting application designed for FRC matches. Originally intended for use by a single team, scouting_app is now open for public use, allowing users to recreate and grow the app as a community. If you use this app, please mention the creator. 😊

## 🔍 General Information

- **Name:** scouting_app
- **Primary Purpose:** To provide a mobile and user-friendly way to scout and record FRC match data.
- **Intended Users:** Initially designed for a single team, now open for public use.
- **Platforms Supported:** Android 📱 (Mobile), with ongoing extensions for Raspberry Pi 🥧 and Windows/Linux computers 🖥️ to host a local area database for immediate data transfer. A Windows ScoutData management app is also in progress.

## ✨ Features and Functionality

- **Main Features:**
  - User-friendly UI. 😍
  - Plugin support for custom functionality. 🔌

- **Data Collection and Storage:**
  - Uses Hive for storage. 🐝
  - Standard variable storing. 📦

- **Data Synchronization:**
  - Utilizes Bluetooth PAN to connect up to 8 devices (standard Windows OS limitation). 🔗

- **Offline Functionality:**
  - Before an event, navigate to Settings > Load Match and enter the upcoming event key to download and store match data locally. 📥

## 🛠️ Technical Details

- **Technologies and Frameworks Used:**
  - Built with Flutter for Android. 🐦

- **Bluetooth PAN for Data Transfer:**
  - Creates a Bluetooth PAN using Windows Bluetooth hotspot. 🔄

- **Main Components:**
  - Hive 🐝
  - TheBlueAlliance API 🌐
  - MaterialUI 🎨

- **Third-Party Services and APIs:**
  - TheBlueAlliance API 🌐
  - Generic Networking API 📡

---

# 🎨 Component Library Documentation

## 📱 Component Overview

The Scout-Ops-Android app features a comprehensive component library located in `lib/components/`. All components follow consistent design patterns and utilize the same typography and color schemes.

### 📂 File Naming Conventions

- **PascalCase** for component files: `Button.dart`, `TextBox.dart`, `CounterShelf.dart`
- **camelCase** for function names: `buildButton()`, `buildTextBoxs()`, `buildCounterShelf()`
- **snake_case** for some utility files: `plugin-tile.dart`, `qr_code_scanner_page.dart`

---

## 🎯 Core Components

### 1. **Button Component** (`Button.dart`)
**Primary interactive button with icon and text**

#### Full Component Code:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildButton({
  required BuildContext context,
  required String text,
  required Color color,
  Color? borderColor,
  Color? iconColor,
  required IconData icon,
  required VoidCallback onPressed,
  Color? textColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
        icon: Icon(icon, size: 24, color: iconColor ?? const Color(0xA1CCC2C2)),
        label: Text(
          text,
          style: GoogleFonts.museoModerno(
            fontSize: 25,
            color: textColor ?? const Color(0xA1CCC2C2),
          ),
        ),
      ),
    ),
  );
}
```

#### Usage Example:
```dart
buildButton(
  context: context,
  text: "Start Match",
  color: Colors.green,
  borderColor: Colors.greenAccent,
  iconColor: Colors.white,
  icon: Icons.play_arrow,
  onPressed: () {
    print("Match started!");
  },
  textColor: Colors.white,
)
```

#### Specifications:
- **Height:** 90px
- **Border Radius:** 20px
- **Padding:** 20px horizontal margin
- **Icon Size:** 24px
- **Typography:** GoogleFonts.museoModerno, 25px
- **Default Colors:** Light grey icon/text `Color(0xA1CCC2C2)`

### 2. **TextBox Component** (`TextBox.dart`)
**Container for grouping related form elements with title and icon**

#### Full Component Code:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/main.dart';
import 'package:scouting_app/services/Colors.dart';

Widget buildTextBoxs(
    String title, List<dynamic> widgetChildren, Icon titleIcon) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode()
            ? lightColors.white
            : const Color.fromARGB(255, 34, 34, 34),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: islightmode()
                ? Colors.grey.withOpacity(0.2)
                : const Color.fromARGB(255, 25, 25, 25),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: islightmode() ? Colors.black : lightColors.white,
                  ),
                  child: titleIcon,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.museoModerno(
                    fontSize: 20,
                    color: islightmode() ? Colors.black : lightColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...widgetChildren.map((child) {
              if (child is Widget) {
                return child;
              } else {
                return Container(); // Fallback for unexpected types
              }
            }),
          ],
        ),
      ),
    ),
  );
}
```

#### Usage Example:
```dart
buildTextBoxs(
  "Match Information",
  [
    TextField(
      decoration: InputDecoration(
        labelText: "Team Number",
        border: OutlineInputBorder(),
      ),
    ),
    SizedBox(height: 8),
    TextField(
      decoration: InputDecoration(
        labelText: "Match Type",
        border: OutlineInputBorder(),
      ),
    ),
  ],
  Icon(Icons.info_outline)
)
```

#### Specifications:
- **Border Radius:** 12px
- **Padding:** 16px all sides + 8px outer margin
- **Background:** White (light mode) / `Color(34, 34, 34)` (dark mode)
- **Shadow:** Grey with opacity 0.2, blur radius 5, offset (0, 3)

### 3. **CounterShelf Component** (`CounterShelf.dart`)
**Interactive counter with increment/decrement buttons**

#### Full Component Code:
```dart
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

class CounterSettings {
  final IconData icon;
  final int number;
  final String counterText;
  final Color color;
  final Function(int) onIncrement;
  final Function(int) onDecrement;

  CounterSettings(
    this.onIncrement,
    this.onDecrement, {
    required this.icon,
    required this.number,
    required this.counterText,
    required this.color,
  });
}

Widget buildCounterShelf(List<CounterSettings> counterSettings) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode()
            ? const Color.fromARGB(255, 255, 255, 255)
            : const Color.fromARGB(255, 34, 34, 34),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        children: counterSettings.map((settings) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                Icon(settings.icon, color: settings.color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    settings.counterText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: !islightmode()
                          ? const Color.fromARGB(255, 255, 255, 255)
                          : const Color.fromARGB(255, 34, 34, 34),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => settings.onDecrement(settings.number),
                  icon: Icon(Icons.remove),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: settings.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    settings.number.toString(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => settings.onIncrement(settings.number),
                  icon: Icon(Icons.add),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}
```

#### Usage Example:
```dart
int scoreCount = 0;
int penaltyCount = 0;

buildCounterShelf([
  CounterSettings(
    (value) => setState(() => scoreCount++),
    (value) => setState(() => scoreCount = max(0, scoreCount - 1)),
    icon: Icons.sports_score,
    number: scoreCount,
    counterText: "Match Score",
    color: Colors.green,
  ),
  CounterSettings(
    (value) => setState(() => penaltyCount++),
    (value) => setState(() => penaltyCount = max(0, penaltyCount - 1)),
    icon: Icons.warning,
    number: penaltyCount,
    counterText: "Penalties",
    color: Colors.red,
  ),
])
```

#### Specifications:
- **Container:** 12px border radius, 8px padding
- **Typography:** 20px, FontWeight.bold
- **Buttons:** Icon buttons with remove/add icons
- **Background:** White (light) / `Color(34, 34, 34)` (dark)

### 4. **Rating Component** (`ratings.dart`)
**Star rating system with customizable icons**

#### Full Component Code:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void DefaultonRatingUpdate(double rating) {
  print(rating);
}

Widget buildRating(String title, IconData icon, double rating, int maxRating,
    Color internaryColor,
    {Function(double)? onRatingUpdate = DefaultonRatingUpdate,
    IconData? icon2}) {
  return Column(
    children: [
      Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
      const SizedBox(height: 8),
      Center(
        child: RatingBar.builder(
          initialRating: rating.toDouble(),
          minRating: 0,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: maxRating,
          glow: true,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(
            icon2 ?? Icons.star,
            color: internaryColor,
          ),
          onRatingUpdate: onRatingUpdate!,
        ),
      ),
    ],
  );
}
```

#### Usage Example:
```dart
double driverRating = 3.5;
double defenseRating = 2.0;

Column(
  children: [
    buildRating(
      "Driver Performance",
      Icons.sports_esports,
      driverRating,
      5,
      Colors.amber,
      onRatingUpdate: (rating) {
        setState(() => driverRating = rating);
        print('Driver Rating: $rating');
      },
      icon2: Icons.star,
    ),
    SizedBox(height: 16),
    buildRating(
      "Defense Capability",
      Icons.shield,
      defenseRating,
      5,
      Colors.blue,
      onRatingUpdate: (rating) {
        setState(() => defenseRating = rating);
      },
      icon2: Icons.security,
    ),
  ],
)
```

#### Specifications:
- **Typography:** 20px, FontWeight.bold
- **Rating Bar:** Horizontal, allows half ratings
- **Item Padding:** 4px horizontal
- **Glow Effect:** Enabled

### 5. **CheckBox Component** (`CheckBox.dart`)
**Large visual checkbox with dotted border**

#### Full Component Code:
```dart
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:scouting_app/main.dart';

Widget buildCheckBox(String title, bool value, Function(bool) onChanged,
    {bool IconOveride = false}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width - 25;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth / 2,
          decoration: BoxDecoration(
            color: islightmode()
                ? const Color.fromARGB(255, 255, 255, 255)
                : const Color.fromARGB(255, 34, 34, 34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    onChanged(!value);
                  },
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: value ? Colors.green : Colors.red,
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: value
                            ? const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 50,
                              )
                            : IconOveride
                                ? const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 50,
                                  )
                                : Container(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: islightmode() ? Colors.black : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
```

#### Usage Example:
```dart
bool robotMoved = false;
bool scoredInAuto = true;
bool climbAttempted = false;

Column(
  children: [
    Row(
      children: [
        Expanded(
          child: buildCheckBox(
            "Robot Moved",
            robotMoved,
            (value) => setState(() => robotMoved = value),
          ),
        ),
        Expanded(
          child: buildCheckBox(
            "Scored in Auto",
            scoredInAuto,
            (value) => setState(() => scoredInAuto = value),
            IconOveride: true, // Shows X when false
          ),
        ),
      ],
    ),
    buildCheckBox(
      "Attempted Climb",
      climbAttempted,
      (value) => setState(() => climbAttempted = value),
    ),
  ],
)
```

#### Specifications:
- **Container Size:** 100px height, responsive width (screen width / 2)
- **Border:** Dotted, 2px stroke, 8px dash pattern
- **Border Radius:** 12px
- **Colors:** Green (checked) / Red (unchecked)
- **Icon Size:** 50px

### 6. **SliderButton Component** (`slider.dart`)
**Swipe-to-confirm button with shimmer effect**

#### Key Component Code Structure:
```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vibration/vibration.dart';

class SliderButton extends StatefulWidget {
  final Widget? child;
  final double radius;
  final double height;
  final double width;
  final double? buttonSize;
  final double? buttonWidth;
  final Color backgroundColor;
  final Color baseColor;
  final Color highlightedColor;
  final Color buttonColor;
  final Widget? label;
  final Alignment alignLabel;
  final BoxShadow? boxShadow;
  final Widget? icon;
  final Future<bool?> Function() action;
  final bool shimmer;
  final bool vibrationFlag;
  final double dismissThresholds;

  const SliderButton({
    Key? key,
    this.child,
    this.radius = 100,
    required this.height,
    required this.width,
    this.buttonSize,
    this.buttonWidth,
    required this.backgroundColor,
    this.baseColor = Colors.white,
    this.highlightedColor = Colors.white,
    required this.buttonColor,
    this.label,
    this.alignLabel = const Alignment(0.6, 0),
    this.boxShadow,
    this.icon,
    required this.action,
    this.shimmer = true,
    this.vibrationFlag = false,
    this.dismissThresholds = 0.75,
  }) : super(key: key);

  @override
  _SliderButtonState createState() => _SliderButtonState();
}

class _SliderButtonState extends State<SliderButton>
    with TickerProviderStateMixin {
  // Implementation details...
}
```

#### Usage Example:
```dart
SliderButton(
  action: () async {
    // Perform your async action
    await Future.delayed(Duration(seconds: 1));
    print("Action completed!");
    return true; // Return true for success, false for failure
  },
  label: Text(
    "Slide to Submit Data",
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  icon: Icon(
    Icons.send,
    color: Colors.white,
  ),
  height: 60,
  width: 300,
  radius: 30,
  backgroundColor: Colors.blue,
  buttonColor: Colors.blueAccent,
  shimmer: true,
  vibrationFlag: true,
  dismissThresholds: 0.8, // 80% of width to trigger
)
```

#### Advanced Usage Example:
```dart
SliderButton(
  action: () async {
    try {
      // Submit match data
      await submitMatchData();
      showSnackBar("Data submitted successfully!");
      return true;
    } catch (e) {
      showSnackBar("Failed to submit data");
      return false;
    }
  },
  label: Container(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload, color: Colors.white),
        SizedBox(width: 8),
        Text(
          "Swipe to Upload",
          style: GoogleFonts.museoModerno(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
  height: 70,
  width: double.infinity,
  radius: 35,
  backgroundColor: Colors.green.shade600,
  buttonColor: Colors.green.shade800,
  baseColor: Colors.green.shade400,
  highlightedColor: Colors.green.shade200,
  shimmer: true,
  vibrationFlag: true,
)
```

#### Specifications:
- **Customizable:** Height, width, colors, radius
- **Effects:** Shimmer animation, vibration feedback
- **Threshold:** Configurable drag distance (default 75%)
- **Async Support:** Handles async actions with loading states

---

## 🎨 Design System

## 🎨 Design System

### 🔤 Typography

**Primary Font:** `GoogleFonts.museoModerno`

#### Font Implementation:
```dart
import 'package:google_fonts/google_fonts.dart';

// Hero Text (70px)
Text(
  "Scout-Ops",
  style: GoogleFonts.museoModerno(
    fontSize: 70,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)

// Page Titles (36px)
Text(
  "Match Scouting",
  style: GoogleFonts.museoModerno(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),
)

// Section Headers (30px)
Text(
  "Autonomous Period",
  style: GoogleFonts.museoModerno(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: Colors.blue,
  ),
)

// Button Text (25px)
Text(
  "Start Match",
  style: GoogleFonts.museoModerno(
    fontSize: 25,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)

// Body Text (20px)
Text(
  "Robot Performance",
  style: GoogleFonts.museoModerno(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  ),
)

// Supporting Text (16px)
Text(
  "Additional notes",
  style: GoogleFonts.museoModerno(
    fontSize: 16,
    color: Colors.grey[600],
  ),
)
```

#### Font Scales:
- **Extra Large:** 70px (Hero text)
- **Large:** 36px (Page titles)
- **Medium:** 30px (Section headers)
- **Regular:** 25px (Button text)
- **Small:** 20px (Body text, counter labels)
- **Extra Small:** 18px, 16px, 14px, 12px (Supporting text)

#### Font Weights:
- **Bold:** `FontWeight.bold` (Headers, labels)
- **Semi-Bold:** `FontWeight.w600` (Sub-headers)
- **Medium:** `FontWeight.w500` (Body text)
- **Normal:** `FontWeight.normal` (Default text)

### 🎨 Color Palette

#### Complete Color System Implementation:
```dart
// Colors.dart - Complete color definitions
import 'dart:ui';

class lightColors {
  static final white = Color.fromARGB(255, 255, 255, 255);
  static final light_red = Color.fromARGB(255, 255, 0, 0);
  static final light_green = Color.fromARGB(255, 0, 255, 0);
  static final light_blue = Color.fromARGB(255, 0, 0, 255);
  static final light_grey = Color.fromARGB(255, 125, 124, 124);
  static final advay_lightdark_red = Color.fromARGB(100, 243, 140, 141);
  static final advay_lightdark_purple = Color.fromARGB(100, 205, 104, 245);
}

class darkColors {
  static final goodblack = const Color(0xFF151515);
  static final advay_dark_red = Color.fromARGB(100, 161, 36, 37);
  static final dark_green = Color.fromARGB(255, 0, 128, 0);
  static final advay_dark_green = Color.fromARGB(100, 58, 106, 29);
  static final dark_blue = Color.fromARGB(255, 0, 0, 128);
  static final advay_dark_blue = Color.fromARGB(100, 44, 46, 147);
  static final advay_dark_purple = Color.fromARGB(100, 110, 16, 146);
}

// Theme detection utility
bool islightmode() {
  // Implementation for detecting current theme
  return MediaQuery.of(context).platformBrightness == Brightness.light;
}
```

#### Color Usage Examples:
```dart
// Background colors
Container(
  color: islightmode() ? lightColors.white : darkColors.goodblack,
  child: YourWidget(),
)

// Alliance-based theming
Color getAllianceColor(String alliance) {
  switch (alliance.toLowerCase()) {
    case 'red':
      return islightmode() 
        ? lightColors.light_red 
        : darkColors.advay_dark_red;
    case 'blue':
      return islightmode() 
        ? lightColors.light_blue 
        : darkColors.advay_dark_blue;
    default:
      return Colors.grey;
  }
}

// Text colors
Text(
  "Dynamic Text",
  style: TextStyle(
    color: islightmode() ? Colors.black : Colors.white,
  ),
)
```

### 🌈 Gradient Patterns

#### Gradient Implementation Examples:
```dart
// Red-to-Blue Alliance Gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFD32F2F), // Red
        Color(0xFF1976D2), // Blue
      ],
      stops: [0.0, 1.0],
    ),
  ),
)

// Orange-to-Purple Accent Gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFFF9800), // Orange
        Color(0xFF9C27B0), // Purple
      ],
    ),
  ),
)

// Multi-Color Brand Gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE53935), // Red
        Color(0xFF8E24AA), // Purple
        Color(0xFF3949AB), // Blue
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  ),
)

// Subtle Background Gradient
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        lightColors.advay_lightdark_red.withOpacity(0.1),
        lightColors.advay_lightdark_purple.withOpacity(0.1),
      ],
    ),
  ),
)

// Alliance-Themed Button Gradient
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  onPressed: onPressed,
  child: Ink(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: alliance == "Red" 
          ? [Color(0xFFD32F2F), Color(0xFFEF5350)]
          : [Color(0xFF1976D2), Color(0xFF42A5F5)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text("Alliance Button"),
    ),
  ),
)
```

#### Gradient Utility Functions:
```dart
// Gradient factory for consistent theming
class GradientFactory {
  static LinearGradient getAllianceGradient(String alliance) {
    switch (alliance.toLowerCase()) {
      case 'red':
        return LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'blue':
        return LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.grey, Colors.grey.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  static LinearGradient getAccentGradient() {
    return LinearGradient(
      colors: [Color(0xFFFF9800), Color(0xFF9C27B0)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  static LinearGradient getSubtleBackground() {
    return LinearGradient(
      colors: [
        Colors.white.withOpacity(0.8),
        Colors.grey.shade50.withOpacity(0.8),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
```

### 📐 Spacing Scale

#### Spacing Constants:
```dart
// spacing.dart - Consistent spacing system
class AppSpacing {
  static const double micro = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// Usage examples
Padding(
  padding: EdgeInsets.all(AppSpacing.large), // 16px
  child: Column(
    children: [
      Text("Title"),
      SizedBox(height: AppSpacing.small), // 8px
      Text("Subtitle"),
      SizedBox(height: AppSpacing.medium), // 12px
      ElevatedButton(
        child: Text("Button"),
        onPressed: () {},
      ),
    ],
  ),
)
```

#### Container Specifications:
```dart
// Standard container styling
Container(
  padding: EdgeInsets.all(AppSpacing.large), // 16px
  margin: EdgeInsets.all(AppSpacing.small), // 8px
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppSpacing.medium), // 12px
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 2,
        blurRadius: 5,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: YourContent(),
)

// Button container
Container(
  height: 90,
  margin: EdgeInsets.symmetric(horizontal: AppSpacing.extraLarge), // 20px
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppSpacing.extraLarge), // 20px
  ),
)
```

#### Consistent Spacing:
- **4px (micro):** Icon padding, tight spacing
- **8px (small):** Component margins, list item spacing
- **12px (medium):** Border radius, card spacing
- **16px (large):** Container padding, section spacing
- **20px (extraLarge):** Button margins, major spacing
- **24px (xxl):** Large section breaks
- **32px (xxxl):** Page-level spacing

---

## 🧩 Additional Components

### 7. **Comment Box Component** (`CommentBox.dart`)
**Text input container for qualitative feedback**

#### Component Code:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

Widget buildCommentsBox(
    String title, String comment, Icon titleIcon, Function(String) onChanged) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: islightmode()
            ? const Color.fromARGB(255, 255, 255, 255)
            : const Color.fromARGB(255, 34, 34, 34),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                titleIcon,
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      color: islightmode() ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: "Enter your comments here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

#### Usage Example:
```dart
String matchComments = "";

buildCommentsBox(
  "Match Notes",
  matchComments,
  Icon(Icons.note_add),
  (value) => setState(() => matchComments = value),
)
```

### 8. **Swipe Cards Component** (`SwipeCards.dart`)
**Match data cards with alliance theming**

#### Component Code:
```dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MatchCard extends StatelessWidget {
  final String matchData;
  final String eventName;
  final String teamNumber;
  final String matchKey;
  final String allianceColor;
  final String selectedStation;

  const MatchCard({
    Key? key,
    required this.matchData,
    required this.eventName,
    required this.teamNumber,
    required this.matchKey,
    required this.allianceColor,
    required this.selectedStation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = allianceColor == "Red"
        ? const Color(0xFFD32F2F)
        : const Color.fromARGB(255, 79, 135, 192);

    final Color secondaryColor = allianceColor == "Red"
        ? const Color(0xFFEF5350)
        : const Color(0xFF42A5F5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
          stops: const [0.3, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card content implementation...
          ],
        ),
      ),
    );
  }
}
```

#### Usage Example:
```dart
MatchCard(
  matchData: jsonEncode(matchInfo),
  eventName: "2025 World Championship",
  teamNumber: "1234",
  matchKey: "2025cmptx_qm1",
  allianceColor: "Red", // or "Blue"
  selectedStation: "Red 1",
)
```

### 9. **Team Info Component** (`TeamInfo.dart`)
**Display team statistics and information**

#### Usage Example:
```dart
// Component for displaying team rankings, stats, and info
Widget buildTeamInfo({
  required String teamNumber,
  required String teamName,
  required Map<String, dynamic> stats,
}) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          "Team $teamNumber",
          style: GoogleFonts.museoModerno(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(teamName),
        // Additional team info...
      ],
    ),
  );
}
```

### 10. **Stopwatch Component** (`stopwatch.dart`)
**Match timing utilities**

#### Usage Example:
```dart
// Stopwatch for tracking match segments
class MatchStopwatch extends StatefulWidget {
  @override
  _MatchStopwatchState createState() => _MatchStopwatchState();
}

class _MatchStopwatchState extends State<MatchStopwatch> {
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  void _startStopwatch() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {});
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatTime(_stopwatch.elapsedMilliseconds),
          style: GoogleFonts.museoModerno(fontSize: 36),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startStopwatch,
              child: Text("Start"),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: _stopStopwatch,
              child: Text("Stop"),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate();
    int minutes = (seconds / 60).truncate();
    return '${minutes.toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
```

### 11. **Navigation Component** (`nav.dart`)
**App navigation system**

#### Usage Example:
```dart
// Bottom navigation bar component
Widget buildBottomNav({
  required int currentIndex,
  required Function(int) onTap,
}) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: onTap,
    type: BottomNavigationBarType.fixed,
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.sports),
        label: 'Match',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Stats',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
  );
}
```

### 12. **QR Code Components**
**QR generation and scanning utilities**

#### QR Generator (`QrGenerator.dart`):
```dart
Widget buildQRCode(String data) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
    ),
  );
}
```

#### QR Scanner Usage:
```dart
// Navigate to QR scanner page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => QrCodeScannerPage(
      onScanned: (String scannedData) {
        print("Scanned: $scannedData");
        // Process scanned data
      },
    ),
  ),
);
```

### 13. **Plugin Tile Component** (`plugin-tile.dart`)
**Plugin system interface tiles**

#### Usage Example:
```dart
Widget buildPluginTile({
  required String title,
  required String description,
  required IconData icon,
  required VoidCallback onTap,
  bool isEnabled = true,
}) {
  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      leading: Icon(
        icon,
        color: isEnabled ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: GoogleFonts.museoModerno(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(description),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
      ),
      onTap: isEnabled ? onTap : null,
    ),
  );
}
```

### 14. **Ratings Box Component** (`RatingsBox.dart`)
**Container for multiple rating components**

#### Usage Example:
```dart
Widget buildRatingsBox({
  required String title,
  required List<Widget> ratings,
}) {
  return Container(
    margin: EdgeInsets.all(8),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.museoModerno(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...ratings,
      ],
    ),
  );
}
```

### 15. **Additional Utility Components**

#### Chips Component (`Chips.dart`):
```dart
Widget buildChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
```

#### Match Selection Component:
```dart
Widget buildMatchSelector({
  required List<String> matches,
  required String selectedMatch,
  required Function(String) onChanged,
}) {
  return DropdownButton<String>(
    value: selectedMatch,
    isExpanded: true,
    items: matches.map((String match) {
      return DropdownMenuItem<String>(
        value: match,
        child: Text(match),
      );
    }).toList(),
    onChanged: (String? newValue) {
      if (newValue != null) {
        onChanged(newValue);
      }
    },
  );
}
```

---

## 🎯 Usage Guidelines

### Complete Match Scouting Page Example:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/components/Button.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/ratings.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/slider.dart';

class MatchScoutingPage extends StatefulWidget {
  @override
  _MatchScoutingPageState createState() => _MatchScoutingPageState();
}

class _MatchScoutingPageState extends State<MatchScoutingPage> {
  // State variables
  int autoScoreCount = 0;
  int teleopScoreCount = 0;
  bool robotMoved = false;
  bool climbSuccessful = false;
  double driverRating = 3.0;
  double defenseRating = 2.5;
  String matchComments = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Match Scouting",
          style: GoogleFonts.museoModerno(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Match Info Section
            buildTextBoxs(
              "Match Information",
              [
                Text(
                  "Team 1234 - Red Alliance",
                  style: GoogleFonts.museoModerno(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text("Qualification Match 15"),
              ],
              Icon(Icons.info_outline),
            ),

            // Autonomous Period
            buildTextBoxs(
              "Autonomous Period",
              [
                buildCounterShelf([
                  CounterSettings(
                    (value) => setState(() => autoScoreCount++),
                    (value) => setState(() => autoScoreCount = max(0, autoScoreCount - 1)),
                    icon: Icons.sports_score,
                    number: autoScoreCount,
                    counterText: "Auto Score",
                    color: Colors.green,
                  ),
                ]),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildCheckBox(
                        "Robot Moved",
                        robotMoved,
                        (value) => setState(() => robotMoved = value),
                      ),
                    ),
                  ],
                ),
              ],
              Icon(Icons.play_arrow),
            ),

            // Teleop Period
            buildTextBoxs(
              "Teleop Period",
              [
                buildCounterShelf([
                  CounterSettings(
                    (value) => setState(() => teleopScoreCount++),
                    (value) => setState(() => teleopScoreCount = max(0, teleopScoreCount - 1)),
                    icon: Icons.sports,
                    number: teleopScoreCount,
                    counterText: "Teleop Score",
                    color: Colors.blue,
                  ),
                ]),
              ],
              Icon(Icons.gamepad),
            ),

            // Endgame
            buildTextBoxs(
              "Endgame",
              [
                buildCheckBox(
                  "Climb Successful",
                  climbSuccessful,
                  (value) => setState(() => climbSuccessful = value),
                ),
              ],
              Icon(Icons.trending_up),
            ),

            // Ratings
            buildTextBoxs(
              "Performance Ratings",
              [
                buildRating(
                  "Driver Skill",
                  Icons.sports_esports,
                  driverRating,
                  5,
                  Colors.amber,
                  onRatingUpdate: (rating) {
                    setState(() => driverRating = rating);
                  },
                ),
                SizedBox(height: 16),
                buildRating(
                  "Defense Capability",
                  Icons.shield,
                  defenseRating,
                  5,
                  Colors.blue,
                  onRatingUpdate: (rating) {
                    setState(() => defenseRating = rating);
                  },
                ),
              ],
              Icon(Icons.star),
            ),

            // Comments
            buildCommentsBox(
              "Additional Notes",
              matchComments,
              Icon(Icons.note_add),
              (value) => setState(() => matchComments = value),
            ),

            // Submit Button
            Padding(
              padding: EdgeInsets.all(16),
              child: SliderButton(
                action: () async {
                  await _submitMatchData();
                  return true;
                },
                label: Text(
                  "Slide to Submit Data",
                  style: GoogleFonts.museoModerno(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: Icon(Icons.send, color: Colors.white),
                height: 70,
                width: double.infinity,
                backgroundColor: Colors.green.shade600,
                buttonColor: Colors.green.shade800,
                shimmer: true,
                vibrationFlag: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMatchData() async {
    // Simulate data submission
    await Future.delayed(Duration(seconds: 2));
    
    Map<String, dynamic> matchData = {
      'autoScore': autoScoreCount,
      'teleopScore': teleopScoreCount,
      'robotMoved': robotMoved,
      'climbSuccessful': climbSuccessful,
      'driverRating': driverRating,
      'defenseRating': defenseRating,
      'comments': matchComments,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print("Match data submitted: $matchData");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Match data submitted successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

### Theme Detection:
All components use `islightmode()` function to detect theme and adjust colors accordingly.

```dart
// Theme detection implementation
bool islightmode() {
  return MediaQuery.of(context).platformBrightness == Brightness.light;
}

// Usage in components
Container(
  color: islightmode() 
    ? Colors.white 
    : Color.fromARGB(255, 34, 34, 34),
  child: YourWidget(),
)
```

### Responsive Design:
- Components use `MediaQuery` for screen-aware sizing
- Flexible layouts with `Expanded` and `LayoutBuilder`
- Consistent aspect ratios

```dart
// Responsive sizing example
Widget responsiveContainer(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  
  return Container(
    width: screenWidth * 0.9, // 90% of screen width
    height: screenHeight * 0.3, // 30% of screen height
    child: YourContent(),
  );
}
```

### Accessibility:
- High contrast colors
- Appropriate touch targets (minimum 44px)
- Semantic icons and labels

```dart
// Accessible button example
buildButton(
  context: context,
  text: "Accessible Button",
  color: Colors.blue,
  icon: Icons.accessibility,
  onPressed: () {},
  // Ensure minimum touch target of 44px
)
```

### Best Practices:
1. **Consistent Spacing:** Use the established spacing scale
2. **Color Harmony:** Stick to alliance-based color schemes
3. **Typography:** Use GoogleFonts.museoModerno consistently
4. **Responsive:** Test on different screen sizes
5. **Theme Support:** Ensure both light and dark mode compatibility

### Integration Example:
```dart
// Import all necessary components
import 'package:scouting_app/components/Button.dart';
import 'package:scouting_app/components/TextBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
// ... other imports

// Use components together
Widget buildScoutingInterface() {
  return Column(
    children: [
      buildTextBoxs(
        "Robot Performance",
        [
          buildCounterShelf([
            CounterSettings(
              increment,
              decrement,
              icon: Icons.score,
              number: score,
              counterText: "Score",
              color: Colors.green,
            ),
          ]),
          buildRating(
            "Performance",
            Icons.star,
            rating,
            5,
            Colors.amber,
          ),
        ],
        Icon(Icons.robot),
      ),
      buildButton(
        context: context,
        text: "Submit",
        color: Colors.blue,
        icon: Icons.send,
        onPressed: submitData,
      ),
    ],
  );
}
```

---

## 🚀 Setup and Usage

### 📋 Prerequisites

- Download the app and start using it. Note that the Template Creator section and Pit data recorder are not active yet.

### 📥 Installation and Configuration

1. Click on the 3 navigation bars ☰.
2. Click on Settings ⚙️.
3. Enter the Scouter Name 🕵️.
4. Give permission for Location 📍, Bluetooth 🔵, and Nearby Devices 📶.
5. To save a local version of a Event, click on Load Match and enter the event key. If the circle turns green, the match has been successfully downloaded, and the app is ready to scout the match completely without internet. 🌐

### 🚀 Starting the App

- Click on the app icon to open it. 📲

## 🛠️ Maintenance and Support

### 🐛 Known Issues and Limitations

- Does not have Pit data recorder and templating features.

### 📬 Reporting Bugs and Requesting Features

- Report bugs and request new features by raising an issue on GitHub.

### 🔮 Future Plans

- There are many planned updates and enhancements.

## 📸 App Pictures

| Description | Image |
| ----------- | ----- |
| Click on Start Match to get started. | <img src="https://github.com/user-attachments/assets/0c4c653e-32fb-4f0f-8af8-c00bcfac009b" alt="Start Match" width="4000"/> |
| This is the Match Selection Page. Fill in the details and go to the Match Tab for selection. | <img src="https://github.com/user-attachments/assets/11fbbf03-fb66-4d8e-99ac-bcf30eab3254" alt="Match Selection Page" width="4000"/> |
| Click on the area where the starting location of the robot was, and use the counter as needed. | <img src="https://github.com/user-attachments/assets/839813c9-7762-4644-b500-4f9a0cf5c53c" alt="Starting Location" width="4000"/> |
| This is your Teleop page. | <img src="https://github.com/user-attachments/assets/3025be9d-9373-47c7-ac3e-adf9bf41aaa5" alt="Teleop Page" width="4000"/> |
| This is your Endgame page. Finish it with a nice Slide to Finalize. | <img src="https://github.com/user-attachments/assets/511edcd7-3af4-4b86-9189-9566686566c1" alt="Endgame Page" width="4000"/> |
| It gives you a compacted QR code with all the details for the scout. If you are using the Opintel Scouz plugin (BLE PAN), the other swipe initiates the data transactions, and you will come to the home page. If you want to see the past matches, you can always click on the 3 bars/navigation rail thingy and go to logs. It shows something like this: | <img src="https://github.com/user-attachments/assets/fd1e38da-0e32-42e7-8938-7a29c9a712a0" alt="Logs" width="4000"/> |

