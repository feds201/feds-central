import 'package:flutter/material.dart';
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
  List<String>? items; // For CheckList
  Set<String>? selectedItems; // For CheckList
  int? counterValue; // For Counter
  TextEditingController? textController; // For TextEditor

  CustomWidget(
    this.widgetType,
    this.label, {
    this.items,
    this.selectedItems,
    this.counterValue,
    this.textController,
  });

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'label': label,
        'items': items,
        'selectedItems': selectedItems?.toList(),
        'counterValue': counterValue,
        'textController': textController?.text,
      };

  factory CustomWidget.fromJson(Map<String, dynamic> json) {
    return CustomWidget(
      json['widgetType'],
      json['label'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(),
      selectedItems: (json['selectedItems'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toSet(),
      counterValue: json['counterValue'],
      textController: json['textController'] != null
          ? TextEditingController(text: json['textController'])
          : null,
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

  CounterSettings(
    this.onIncrement,
    this.onDecrement, {
    required this.icon,
    required this.number,
    required this.counterText,
    required this.color,
  });
}

class _ChecklistsState extends State<Checklists> {
  void initState() {
    super.initState();
  }


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Not Implemented Y&ET'),
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
          // ...customWidgets.asMap().entries.map((entry) {
          //   int index = entry.key;
          //   CustomWidget customWidget = entry.value;
          //   return buildCustomWidget(customWidget, index);
          // }).toList(),
        ],
      ),
    );
  }


}
// class _ChecklistsState extends State<Checklists> {
//   List<CustomWidget> customWidgets = [];
//   bool isEditing = false;
//
//   @override
//   void initState() {
//     super.initState();
//     loadTemplate();
//   }
//
//   void addCustomWidget(String widgetType, String label) {
//     setState(() {
//       customWidgets.add(CustomWidget(widgetType, label));
//       saveTemplate();
//     });
//   }
//
//   void saveTemplate() async {
//     final box = await Hive.openBox('pitData');
//     box.put(
//         'template', customWidgets.map((widget) => widget.toJson()).toList());
//   }
//
//   void loadTemplate() async {
//     final box = await Hive.openBox('pitData');
//     final template = box.get('template', defaultValue: []);
//     setState(() {
//       customWidgets = (template as List)
//           .map((item) => CustomWidget.fromJson(item))
//           .toList();
//     });
//   }
//
//   void removeCustomWidget(int index) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Confirm Delete"),
//           content: const Text("Are you sure you want to delete this widget?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   customWidgets.removeAt(index);
//                   saveTemplate();
//                 });
//                 Navigator.of(context).pop();
//               },
//               child: const Text("Delete"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget buildCustomWidget(CustomWidget customWidget, int index) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: _buildWidget(customWidget),
//           ),
//           if (isEditing)
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () {
//                 removeCustomWidget(index);
//               },
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildWidget(CustomWidget customWidget) {
//     Widget widgetContent;
//
//     switch (customWidget.widgetType) {
//       case 'CheckList':
//         widgetContent = Column(
//           children: customWidget.items!.map((item) {
//             return CheckboxListTile(
//               title: Text(item),
//               value: customWidget.selectedItems?.contains(item) ?? false,
//               onChanged: (bool? value) {
//                 setState(() {
//                   if (value == true) {
//                     customWidget.selectedItems?.add(item);
//                   } else {
//                     customWidget.selectedItems?.remove(item);
//                   }
//                   saveTemplate();
//                 });
//               },
//             );
//           }).toList(),
//         );
//         break;
//
//       case 'Counter':
//         widgetContent = buildCounterShelf([
//           CounterSettings(
//             onIncrement: (int value) {
//               setState(() {
//                 customWidget.counterValue = (customWidget.counterValue ?? 0) + 1;
//                 saveTemplate();
//               });
//             },
//             onDecrement: (int value) {
//               setState(() {
//                 customWidget.counterValue = (customWidget.counterValue ?? 0) - 1;
//                 saveTemplate();
//               });
//             },
//             icon: Icons.add,
//             number: customWidget.counterValue ?? 0,
//             counterText: customWidget.label,
//             color: Colors.blue,
//           ),
//         ]);
//         break;
//
//       case 'CameraShutter':
//         widgetContent = IconButton(
//           icon: Icon(Icons.camera_alt),
//           onPressed: () {
//             // Trigger camera shutter
//           },
//         );
//         break;
//
//       case 'TextEditor':
//         widgetContent = TextField(
//           controller: customWidget.textController ?? TextEditingController(),
//           decoration: InputDecoration(
//             hintText: 'Enter text...',
//             border: OutlineInputBorder(),
//           ),
//           maxLines: null,
//           onChanged: (text) {
//             saveTemplate();
//           },
//         );
//         break;
//
//       case 'ImageOption':
//         widgetContent = IconButton(
//           icon: Icon(Icons.image),
//           onPressed: () {
//             // Handle image option
//           },
//         );
//         break;
//
//       default:
//         return Container();
//     }
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         widgetContent,
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Record Checklist for ${widget.team.teamNumber}'),
//         actions: [
//           IconButton(
//             icon: Icon(isEditing ? Icons.check : Icons.edit),
//             onPressed: () {
//               setState(() {
//                 isEditing = !isEditing;
//               });
//             },
//           ),
//           IconButton(
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (BuildContext context) {
//                   String newWidgetType = 'CheckList';
//                   String newLabel = '';
//                   return AlertDialog(
//                     title: const Text("Add New Widget"),
//                     content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         DropdownButton<String>(
//                           value: newWidgetType,
//                           onChanged: (String? newValue) {
//                             setState(() {
//                               newWidgetType = newValue!;
//                             });
//                           },
//                           items: <String>[
//                             'CheckList',
//                             'Counter',
//                             'CameraShutter',
//                             'TextEditor'
//                           ].map<DropdownMenuItem<String>>((String value) {
//                             return DropdownMenuItem<String>(
//                               value: value,
//                               child: Text(value),
//                             );
//                           }).toList(),
//                         ),
//                         TextField(
//                           onChanged: (value) {
//                             newLabel = value;
//                           },
//                           decoration: const InputDecoration(
//                               hintText: "Enter widget label"),
//                         ),
//                       ],
//                     ),
//                     actions: [
//                       TextButton(
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                         child: const Text("Cancel"),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           if (newLabel.isNotEmpty) {
//                             addCustomWidget(newWidgetType, newLabel);
//                             Navigator.of(context).pop();
//                           }
//                         },
//                         child: const Text("Add"),
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//             icon: const Icon(Icons.add),
//           ),
//         ],
//       ),
//       body: ListView(
//         children: [
//           TeamInfo(
//             teamNumber: widget.team.teamNumber,
//             nickname: widget.team.nickname,
//             city: widget.team.city,
//             stateProv: widget.team.stateProv,
//             country: widget.team.country,
//             website: widget.team.website,
//           ),
//           ...customWidgets.asMap().entries.map((entry) {
//             int index = entry.key;
//             CustomWidget customWidget = entry.value;
//             return buildCustomWidget(customWidget, index);
//           }).toList(),
//         ],
//       ),
//     );
//   }
// }