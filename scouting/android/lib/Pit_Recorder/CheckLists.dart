import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'Pit_Recorder.dart';

class Checklists extends StatefulWidget {
  final Team team;
  const Checklists({super.key, required this.team});

  @override
  State<StatefulWidget> createState() => _ChecklistsState();
}

class _ChecklistsState extends State<Checklists> {
  List<ScoutingItem> scoutingItems = [];
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadScoutingItems();
  }

  void _loadScoutingItems() async {
    final box = Hive.box('scoutingItems');
    final items = box.get('items', defaultValue: []);
    setState(() {
      scoutingItems =
          (items as List).map((item) => ScoutingItem.fromJson(item)).toList();
    });
  }

  void _addScoutingItem(ScoutingItem item) async {
    final box = Hive.box('scoutingItems');
    scoutingItems.add(item);
    await box.put('items', scoutingItems.map((item) => item.toJson()).toList());
    setState(() {});
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Options'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAddWidgetDialog();
                },
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddWidgetDialog() {
    final labelController = TextEditingController();
    final optionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Scouting Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: optionsController,
                decoration:
                    InputDecoration(labelText: 'Options (comma separated)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final label = labelController.text;
                final options = optionsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList();
                final newItem = ScoutingItem(label, options);
                _addScoutingItem(newItem);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget buildScoutingItem(ScoutingItem item, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (item.options.isNotEmpty)
              ...item.options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: item.selectedOptions.contains(option),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        item.selectedOptions.add(option);
                      } else {
                        item.selectedOptions.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            if (item.options.isEmpty) FreeResponseWidget(item: item),
            if (isEditing)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      scoutingItems.removeAt(index);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checklists for ${widget.team.nickname}'),
      ),
      body: ListView.builder(
        itemCount: scoutingItems.length,
        itemBuilder: (context, index) {
          return buildScoutingItem(scoutingItems[index], index);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

class ScoutingItem {
  final String label;
  final List<String> options;
  final Set<String> selectedOptions;
  String? freeResponse;

  ScoutingItem(this.label, this.options) : selectedOptions = {};

  Map<String, dynamic> toJson() => {
        'label': label,
        'options': options,
        'selectedOptions': selectedOptions.toList(),
        'freeResponse': freeResponse,
      };

  factory ScoutingItem.fromJson(Map<String, dynamic> json) {
    return ScoutingItem(
      json['label'],
      (json['options'] as List<dynamic>).map((item) => item as String).toList(),
    )
      ..selectedOptions.addAll(
        (json['selectedOptions'] as List<dynamic>)
            .map((item) => item as String),
      )
      ..freeResponse = json['freeResponse'];
  }
}

class FreeResponseWidget extends StatelessWidget {
  final ScoutingItem item;

  const FreeResponseWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(labelText: 'Enter your response'),
      onChanged: (value) {
        item.freeResponse =
            value; // Update the free response in the scouting item
      },
    );
  }
}
