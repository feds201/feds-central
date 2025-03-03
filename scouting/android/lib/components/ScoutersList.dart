import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class ScouterList extends StatefulWidget {
  const ScouterList({super.key});

  @override
  _ScouterListState createState() => _ScouterListState();
}

class _ScouterListState extends State<ScouterList> {
  final List<dynamic> _scouterNames =
      Hive.box('userData').get('scouterNames', defaultValue: []);
  String _selectedChip =
      Hive.box('settings').get('deviceName', defaultValue: '');

  void _addScouter() {
    String newName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          title: Text(
            'Add Scouter',
            style: GoogleFonts.museoModerno(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          content: TextField(
            onChanged: (value) => newName = value,
            style: TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: "Enter name",
              hintStyle: TextStyle(color: Colors.grey[600]),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.trim().isNotEmpty) {
                  setState(() {
                    _scouterNames.add(newName.trim());
                    Hive.box('userData').put('scouterNames', _scouterNames);
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Add', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _deleteScouter(String name) {
    setState(() {
      _scouterNames.remove(name);
      Hive.box('userData').put('scouterNames', _scouterNames);
      if (_selectedChip == name) {
        _selectedChip = ''; // Reset selection if deleted
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      color: Colors.white,
      shadowColor: Colors.grey[300],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scouters Account',
              style: GoogleFonts.museoModerno(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scouterNames.map((name) {
                return ChoiceChip(
                  label: Text(name,
                      style: GoogleFonts.museoModerno(
                          fontSize: 16,
                          color: _selectedChip == name
                              ? Colors.white
                              : Colors.black87)),
                  selected: _selectedChip == name,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedChip = selected ? name : '';
                      Hive.box('settings').put('deviceName', _selectedChip);
                    });
                  },
                  selectedColor: Colors.blueAccent,
                  backgroundColor: Colors.grey[100],
                  labelPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.blueAccent, width: 1.2)),
                  elevation: _selectedChip == name ? 4 : 0,
                  avatar: _selectedChip == name
                      ? Icon(Icons.check_circle, color: Colors.white, size: 20)
                      : null,
                );
              }).toList() as List<Widget>,
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addScouter,
                icon: Icon(Icons.person_add, color: Colors.white),
                label: Text('Add Scouter',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.blueAccent,
                  shadowColor: Colors.blueAccent.withOpacity(0.3),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
