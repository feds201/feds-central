import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:scouting_app/services/DataBase.dart';

/// BotLocation position update callback
typedef BotLocationCallback = void Function(BotLocation location);

class InteractiveMapMarker extends StatefulWidget {
  final BotLocation botLocation;
  final String allianceColor;
  final BotLocationCallback? onLocationChanged;
  final Image? backgroundImage;

  const InteractiveMapMarker({
    Key? key,
    required this.botLocation,
    required this.allianceColor,
    this.onLocationChanged,
    this.backgroundImage,
  }) : super(key: key);

  @override
  _InteractiveMapMarkerState createState() => _InteractiveMapMarkerState();
}

class _InteractiveMapMarkerState extends State<InteractiveMapMarker> {
  late BotLocation _botLocation;
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isRotating = false;

  @override
  void initState() {
    super.initState();
    _botLocation = widget.botLocation
        .copy(); // Create a copy to avoid modifying the original
  }

  void _updateLocation() {
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(_botLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Image backgroundImage = widget.backgroundImage ??
        Image.asset(
            'assets/2026/${widget.allianceColor}Alliance_StartPosition.png');

    final double _size =
        math.max(_botLocation.size.width, _botLocation.size.height);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2.0,
              blurRadius: 5.0,
              offset: const Offset(0.0, 3.0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(7.0),
          child: Stack(
            children: [
              // Background image (field map)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: backgroundImage,
              ),

              // Robot marker with gesture detectors
              Positioned(
                left: _botLocation.position.dx - _size / 2,
                top: _botLocation.position.dy - _size / 2,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _isDragging = true),
                  onPanUpdate: (details) {
                    setState(() {
                      _botLocation.position += details.delta;
                      _updateLocation();
                    });
                  },
                  onPanEnd: (_) => setState(() => _isDragging = false),
                  child: Transform.rotate(
                    angle: _botLocation.angle,
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_size / 2),
                        border: Border.all(
                          color: _isDragging
                              ? Colors.blue.withOpacity(0.8)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // The robot image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(_size / 2),
                            child: Image.asset(
                              'assets/Swerve.png',
                              width: _size,
                              height: _size,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Resize handle
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onPanStart: (_) =>
                                  setState(() => _isResizing = true),
                              onPanUpdate: (details) {
                                setState(() {
                                  // Calculate new size based on drag
                                  final newSize = math.max(
                                      20.0,
                                      _size +
                                          details.delta.dx +
                                          details.delta.dy);
                                  _botLocation.size = Size(newSize, newSize);
                                  _updateLocation();
                                });
                              },
                              onPanEnd: (_) =>
                                  setState(() => _isResizing = false),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _isResizing
                                      ? Colors.green.withOpacity(0.8)
                                      : Colors.green.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.open_in_full,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Rotation handle
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onPanStart: (_) =>
                                  setState(() => _isRotating = true),
                              onPanUpdate: (details) {
                                final centerPoint =
                                    Offset(_size / 2, _size / 2);
                                final touchPoint = details.localPosition;

                                // Calculate the angle between center and touch point
                                final angle = math.atan2(
                                  touchPoint.dy - centerPoint.dy,
                                  touchPoint.dx - centerPoint.dx,
                                );

                                setState(() {
                                  _botLocation.angle = angle;
                                  _updateLocation();
                                });
                              },
                              onPanEnd: (_) =>
                                  setState(() => _isRotating = false),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _isRotating
                                      ? Colors.orange.withOpacity(0.8)
                                      : Colors.orange.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.rotate_right,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this to your BotLocation class if it doesn't already exist
extension BotLocationExtension on BotLocation {
  BotLocation copy() {
    return BotLocation(
      Offset(position.dx, position.dy),
      Size(size.width, size.height),
      angle,
    );
  }
}

// Updated buildMap function to use BotLocation
Widget buildMap(
  BuildContext context,
  BotLocation botLocation,
  String allianceColor, {
  Function(TapUpDetails)? onTap,
  Image? image,
  Function(BotLocation)? onLocationChanged,
}) {
  // If we have location callbacks, use the new interactive widget
  if (onLocationChanged != null) {
    return InteractiveMapMarker(
      botLocation: botLocation,
      allianceColor: allianceColor,
      backgroundImage: image,
      onLocationChanged: onLocationChanged,
    );
  }

  // Otherwise use the original implementation
  onTap ??= (_) {};
  image ??=
      Image.asset('assets/2026/${allianceColor}Alliance_StartPosition.png');

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2.0,
            blurRadius: 5.0,
            offset: const Offset(0.0, 3.0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7.0),
        child: Stack(
          children: [
            GestureDetector(
              onTapUp: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: image,
              ),
            ),
            Positioned(
              left: botLocation.position.dx - botLocation.size.width / 2,
              top: botLocation.position.dy - botLocation.size.height / 2,
              child: Transform.rotate(
                angle: botLocation.angle,
                child: SizedBox(
                  width: botLocation.size.width,
                  height: botLocation.size.height,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(botLocation.size.width / 2),
                    child: Image.asset('assets/Swerve.png'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
