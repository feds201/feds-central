import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import '../components/RatingsBox.dart';
import '../components/TeamInfo.dart';
import 'Pit_Recorder.dart';

class Checklists extends StatefulWidget {
  final Team team;
  const Checklists({super.key, required this.team});

  @override
  State<StatefulWidget> createState() => _ChecklistsState();
}

class CustomWidget {
  final String widgetType;
  final String label;

  CustomWidget(this.widgetType, this.label);

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'label': label,
      };

  factory CustomWidget.fromJson(Map<String, dynamic> json) {
    return CustomWidget(
      json['widgetType'],
      json['label'],
    );
  }
}

class CounterSettings {
  final IconData icon;
  final int number;
  final String counterText;
  final Color color;
  final Function(int) onIncrement;
  final Function(int) onDecrement;

  CounterSettings(this.onIncrement, this.onDecrement, {
    required this.icon,
    required this.number,
    required this.counterText,
    required this.color,
  });
}

class _ChecklistsState extends State<Checklists> {
  List<CustomWidget> customWidgets = [];
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    loadTemplate();
  }

  void addCustomWidget(String widgetType, String label) {
    setState(() {
      customWidgets.add(CustomWidget(widgetType, label));
      saveTemplate();
    });
  }

  void saveTemplate() async {
    final box = await Hive.openBox('pitData');
    box.put('template', customWidgets.map((widget) => widget.toJson()).toList());
  }

  void loadTemplate() async {
    final box = await Hive.openBox('pitData');
    final template = box.get('template', defaultValue: []);
    setState(() {
      customWidgets = (template as List).map((item) => CustomWidget.fromJson(item)).toList();
    });
  }

  void removeCustomWidget(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this widget?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  customWidgets.removeAt(index);
                  saveTemplate();
                });
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget buildCustomWidget(CustomWidget customWidget, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildWidget(customWidget),
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                removeCustomWidget(index);
              },
            ),
        ],
      ),
    );
  }

  Object _buildWidget(CustomWidget customWidget) {
    switch (customWidget.widgetType) {
      case 'CheckList':
        return CheckboxListTile(
          title: Text(customWidget.label),
          value: false,
          onChanged: (bool? value) {
            setState(() {
              // Handle checkbox state change
            });
          },
        );
      case 'Counter':
        return
          CounterSettings(
            onIncrement: (int value) {
              setState(() {
                // Handle counter increment
              });
            },
            onDecrement: (int value) {
              setState(() {
                // Handle counter decrement
              });
            },
            icon: Icons.add,
            number: 0,
            counterText: customWidget.label,
            color: Colors.blue,
          );
      case 'CameraShutter':
        return ElevatedButton(
          onPressed: () {
            // Handle camera shutter action
          },
          child: Text(customWidget.label),
        );
      case 'TextEditor':
        return TextField(
          decoration: InputDecoration(
            labelText: customWidget.label,
          ),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Checklist for ${widget.team.teamNumber}'),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String newWidgetType = 'CheckList';
                  String newLabel = '';
                  return AlertDialog(
                    title: const Text("Add New Widget"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: newWidgetType,
                          onChanged: (String? newValue) {
                            setState(() {
                              newWidgetType = newValue!;
                            });
                          },
                          items: <String>[
                            'CheckList',
                            'Counter',
                            'CameraShutter',
                            'TextEditor'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        TextField(
                          onChanged: (value) {
                            newLabel = value;
                          },
                          decoration: const InputDecoration(
                              hintText: "Enter widget label"),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          if (newLabel.isNotEmpty) {
                            addCustomWidget(newWidgetType, newLabel);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text("Add"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        children: [
          TeamInfo(
            teamNumber: widget.team.teamNumber,
            nickname: widget.team.nickname,
            city: widget.team.city,
            stateProv: widget.team.stateProv,
            country: widget.team.country,
            website: widget.team.website,
          ),
          ...customWidgets.asMap().entries.map((entry) {
            int index = entry.key;
            CustomWidget customWidget = entry.value;
            return buildCustomWidget(customWidget, index);
          }).toList(),
        ],
      ),
    );
  }
}