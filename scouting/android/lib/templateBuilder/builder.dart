import 'package:flutter/material.dart';

class TemplateBuilder extends StatefulWidget {
  const TemplateBuilder({super.key});

  @override
  _TemplateBuilderState createState() => _TemplateBuilderState();
}

class _TemplateBuilderState extends State<TemplateBuilder> {
  Map<String, dynamic> template = {
    'Auton': [],
    'TeleOp': [],
    'Endgame': [],
  };

  // Available ScoutOps widgets to choose from (you'll need to fill this with your actual widgets)
  final List<String> availableWidgets = [
    'Button',
    'TextField',
    'Slider',
    'Switch'
  ];

  void _addWidget(String phase, String widgetType) {
    setState(() {
      template[phase]?.add({'type': widgetType, 'properties': {}});
    });
  }

  void _openWidgetSelector(String phase) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return ListView(
            children: availableWidgets.map((widgetType) {
              return ListTile(
                title: Text(widgetType),
                onTap: () {
                  _addWidget(phase, widgetType);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          );
        });
  }

  Widget _buildPhase(String phase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(phase,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton(
          onPressed: () => _openWidgetSelector(phase),
          child: Text('Add Widget to $phase'),
        ),
        ...template[phase]?.map<Widget>((widgetInfo) {
              return ListTile(
                title: Text(widgetInfo['type']),
              );
            }).toList() ??
            [],
      ],
    );
  }

  String generateTemplateJSON() {
    return template
        .toString(); // Convert to JSON format, you can use json.encode() for actual JSON
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Template Builder'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Generate JSON and perform save operation
              String jsonTemplate = generateTemplateJSON();
              print('Generated Template JSON: $jsonTemplate');
              // You can add functionality to save this JSON to a file or upload it
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhase('Auton'),
            _buildPhase('TeleOp'),
            _buildPhase('Endgame'),
          ],
        ),
      ),
    );
  }
}
