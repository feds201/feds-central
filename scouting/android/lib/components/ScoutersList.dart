import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:confetti/confetti.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../main.dart';
import '../services/Colors.dart';

class ScouterList extends StatefulWidget {
  const ScouterList({super.key});

  @override
  _ScouterListState createState() => _ScouterListState();
}

class _ScouterListState extends State<ScouterList>
    with SingleTickerProviderStateMixin {
  final List<dynamic> _scouterNames =
      Hive.box('userData').get('scouterNames', defaultValue: []);
  String _selectedChip =
      Hive.box('settings').get('deviceName', defaultValue: '');
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  String _randomScouter = '';

  final List<Color> _avatarColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.orange,
    Colors.indigo,
    Colors.cyan,
  ];

  final List<IconData> _avatarIcons = [
    Icons.rocket_launch,
    Icons.sports_esports,
    Icons.engineering,
    Icons.psychology,
    Icons.science,
    Icons.code,
    Icons.lightbulb,
    Icons.auto_awesome,
    Icons.emoji_events,
    Icons.anchor,
    Icons.airline_seat_legroom_extra,
    Icons.cookie,
    Icons.cyclone,
    Icons.handyman,
    Icons.baby_changing_station,
    Icons.sports_soccer,
    Icons.sports_tennis,
    Icons.local_taxi,
    Icons.self_improvement,
    Icons.smartphone,
    Icons.flutter_dash,
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addScouter() {
    String newName = '';
    Color selectedColor = _avatarColors[Random().nextInt(_avatarColors.length)];
    IconData selectedIcon = _avatarIcons[Random().nextInt(_avatarIcons.length)];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: islightmode() ? Colors.white : darkColors.goodblack,
          title: Row(
            children: [
              Icon(Icons.person_add_alt_1, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text(
                'Add New Scouter',
                style: GoogleFonts.museoModerno(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: islightmode() ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => newName = value,
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Enter scouter name",
                    hintStyle: TextStyle(color: const Color.fromARGB(255, 223, 222, 222)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: const Color.fromARGB(14, 245, 245, 245),
                    prefixIcon: Icon(Icons.badge, color: Colors.blueAccent),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Choose Avatar Color',
                  style: TextStyle(fontWeight: FontWeight.bold, color: islightmode() ? Colors.black : Colors.white),
                  
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _avatarColors.map((color) {
                    return GestureDetector(
                      onTap: () {
                        selectedColor = color;
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                Text(
                  'Choose Avatar Icon',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  children: _avatarIcons.map((icon) {
                    return GestureDetector(
                      onTap: () {
                        selectedIcon = icon;
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: Colors.blueAccent),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: Icon(Icons.cancel_outlined, color: Colors.redAccent),
              label: Text('Cancel',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              onPressed: () => Navigator.pop(context),
              onLongPress: () {
                setState(() {
                  _scouterNames.clear();
                  Hive.box('userData').put('scouterNames', _scouterNames);
                });
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.add_circle, color: Colors.white),
              label: Text('Add', style: TextStyle(fontSize: 16)),
              onPressed: () {
                if (newName.trim().isNotEmpty) {
                  setState(() {
                    // Create the new scouter data
                    Map<String, dynamic> scouter = {
                      'name': newName.trim(),
                      'color': selectedColor.value,
                      'icon': selectedIcon.codePoint,
                    };

                    // Create a completely new list with converted data
                    List<Map<String, dynamic>> newList = [];

                    // First convert any existing string entries to map format
                    for (var item in _scouterNames) {
                      if (item is String) {
                        // Convert string to map
                        newList.add({
                          'name': item,
                          'color': _avatarColors[
                                  newList.length % _avatarColors.length]
                              .value,
                          'icon':
                              _avatarIcons[newList.length % _avatarIcons.length]
                                  .codePoint,
                        });
                      } else if (item is Map<String, dynamic>) {
                        // Keep existing map
                        newList.add(item);
                      }
                    }

                    // Add the new scouter
                    newList.add(scouter);

                    // Replace the old list with the new one
                    _scouterNames.clear();
                    _scouterNames.addAll(newList);

                    // Save to Hive
                    Hive.box('userData').put('scouterNames', _scouterNames);
                  });
                  _confettiController.play();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectRandomScouter() {
    if (_scouterNames.isEmpty) return;

    setState(() {
      _randomScouter = '';
    });

    _animationController.forward(from: 0.0);

    Future.delayed(Duration(milliseconds: 800), () {
      setState(() {
        final random = Random().nextInt(_scouterNames.length);
        final scouter = _scouterNames[random];

        // Handle both string and map formats
        if (scouter is String) {
          _randomScouter = scouter;
        } else if (scouter is Map) {
          _randomScouter = scouter['name'] ?? 'Unknown';
        } else {
          _randomScouter = "Scouter ${random + 1}";
        }

        _confettiController.play();
      });
    });
  }

  void _removeScouter(int index) {
    // Handle both string and map data formats
    final scouter = _scouterNames[index];
    String name;

    // Check if the scouter data is a string or a map
    if (scouter is String) {
      name = scouter;
    } else if (scouter is Map) {
      name = scouter['name'] ?? 'Unknown';
    } else {
      name = "Scouter ${index + 1}";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Scouter?', style: GoogleFonts.museoModerno()),
        content: Text('Are you sure you want to remove $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete_forever, color: Colors.white),
            label: Text('Remove'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                // Also handle string/map difference when checking selected chip
                if (_selectedChip == name) {
                  _selectedChip = '';
                  Hive.box('settings').put('deviceName', _selectedChip);
                }
                _scouterNames.removeAt(index);
                Hive.box('userData').put('scouterNames', _scouterNames);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Card(
          margin: const EdgeInsets.all(20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: Colors.blueAccent.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: islightmode() ? [Colors.white, Colors.blue.shade50] : [darkColors.goodblack, const Color.fromARGB(255, 38, 113, 167)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt,
                            size: 28, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Text(
                          'Scouting Team',
                          style: GoogleFonts.museoModerno(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: islightmode() ? Colors.black87 : const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.shuffle, color: Colors.purpleAccent),
                      tooltip: 'Pick Random Scouter',
                      onPressed: _selectRandomScouter,
                    ),
                  ],
                ),

                if (_randomScouter.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.purpleAccent,
                              Colors.deepPurpleAccent
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Random Scouter Selected:",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              _randomScouter,
                              style: GoogleFonts.museoModerno(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                _scouterNames.isEmpty
                    ? Center(
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              'Add your first scouter!',
                              textStyle: GoogleFonts.museoModerno(
                                fontSize: 18,
                                color: islightmode() ? Colors.blueGrey : const Color.fromARGB(255, 167, 169, 197),
                              ),
                              speed: Duration(milliseconds: 100),
                            ),
                          ],
                          totalRepeatCount: 1,
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_scouterNames.length, (index) {
                          // Handle both string and map data formats
                          final scouter = _scouterNames[index];
                          String name;
                          Color color;
                          IconData iconData;

                          // Check if the scouter data is a string or a map
                          if (scouter is String) {
                            name = scouter;
                            color = _avatarColors[index % _avatarColors.length];
                            iconData =
                                _avatarIcons[index % _avatarIcons.length];
                          } else if (scouter is Map) {
                            name = scouter['name'] ?? 'Unknown';
                            color =
                                Color(scouter['color'] ?? Colors.blue.value);
                            iconData = IconData(
                              scouter['icon'] ?? Icons.person.codePoint,
                              fontFamily: 'MaterialIcons',
                            );
                          } else {
                            // Fallback for unexpected data type
                            name = "Scouter ${index + 1}";
                            color = Colors.grey;
                            iconData = Icons.person;
                          }

                          return Dismissible(
                            key: Key(name + index.toString()),
                            background: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              child: Icon(Icons.delete_forever,
                                  color: Colors.white),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _removeScouter(index),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              child: ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color.withOpacity(0.2),
                                      radius: 14,
                                      child: Icon(iconData,
                                          color: color, size: 16),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: GoogleFonts.museoModerno(
                                        fontSize: 16,
                                        color: _selectedChip == name
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: _selectedChip == name,
                                onSelected: (bool selected) {
                                  setState(() {
                                    // Store only the name string, not the whole scouter object
                                    _selectedChip = selected ? name : '';
                                    Hive.box('settings')
                                        .put('deviceName', _selectedChip);
                                    if (selected) _confettiController.play();
                                  });
                                },
                                selectedColor: color.withAlpha(80),
                                backgroundColor: Colors.white,
                                labelPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: color, width: 1.2),
                                ),
                                elevation: _selectedChip == name ? 6 : 0,
                                shadowColor: _selectedChip == name
                                    ? color.withOpacity(0.4)
                                    : Colors.transparent,
                              ),
                            ),
                          );
                        }),
                      ),

                const SizedBox(height: 20),

                // Add Scouter Button with Animation
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.person_add_alt_1, color: Colors.white),
                    label: Text('Add Scouter', style: TextStyle(fontSize: 16)),
                    onPressed: _addScouter,
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: Colors.blueAccent.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Confetti Effect
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          particleDrag: 0.05,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.1,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
            Colors.red,
            Colors.yellow,
          ],
        ),
      ],
    );
  }
}
