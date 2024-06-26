import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'components/nav.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'match.dart';
import 'package:appinio_swiper/appinio_swiper.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  final TextEditingController eventKeyController = TextEditingController();
  Future<List<dynamic>>? matches;
  bool isLoading = false;
  int _selectedIndex = 0;

  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Match'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                Variables.allianceColor = null;
                matches = null;
                Variables.eventKey = null;
                eventKeyController.clear();
                isLoading = false;
              });
            },
          ),
        ],
      ),
      body: matchPage(context, _selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Match',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  matchPage(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return setup(context);
      case 1:
        return matchSelection(context);
    }
  }

  List<Widget> modules(BuildContext context) {
    return [
      const SizedBox(height: 10),
      TextField(
        controller: eventKeyController,
        decoration: InputDecoration(
          labelText: 'Match Event Key (e.g. 2023cmptx)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLoading ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(MediaQuery.of(context).size.width / 2, 50),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                onPressed: () => getData(eventKeyController.text),
                child: const Text('Load Event'),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Variables.allianceColor == 'Red'
                      ? Colors.red
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.red)),
                ),
                onPressed: () {
                  setState(() {
                    Variables.allianceColor = 'Red';
                  });
                },
                child: const Text('Red'),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Variables.allianceColor == 'Blue'
                      ? Colors.blue
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    Variables.allianceColor = 'Blue';
                  });
                },
                child: const Text('Blue'),
              ),
            ),
          ),
        ],
      ),
      if (Variables.allianceColor == "Red") ...[
        const SizedBox(height: 10),
        Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Variables.selectedStation = "R1";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R1'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Variables.selectedStation = "R2";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R2'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Variables.selectedStation = "R3";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R3'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/${Variables.allianceColor}Alliance.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                  ),
                ],
              ),
            )
          ],
        ),
      ] else if (Variables.allianceColor == "Blue") ...[
        const SizedBox(height: 10),
        Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Variables.selectedStation = "R1";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R1'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Variables.selectedStation = "R2";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R2'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Variables.selectedStation = "R3";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R3'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/${Variables.allianceColor}Alliance.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                  ),
                ],
              ),
            )
          ],
        ),
      ]
    ];
  }

  getData(String eventKey) async {
    setState(() {
      isLoading = true;
    });

    var headers = {
      'X-TBA-Auth-Key':
          '2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W'
    };
    var response = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/matches'),
        headers: headers);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (kDebugMode) {
        print(data);
      }

      Variables.file = data.toString();

      await writeJson(data);

      setState(() {
        matches = readJson();
        isLoading = false;
      });
    } else {
      if (kDebugMode) {
        print('Failed to load data');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> writeJson(List<dynamic> data) async {
    final path = await _localPath;
    final file = File('$path/data.json');

    return file.writeAsString(jsonEncode(data));
  }

  Future<List<dynamic>> readJson() async {
    try {
      final path = await _localPath;
      final file = File('$path/data.json');
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      return [];
    }
  }

  Widget setup(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: modules(context),
        ),
      ),
    );
  }

  Widget matchSelection(BuildContext context) {
    return Row(
      children: <Widget>[
        // Navigation Rail
        NavigationRail(
          leading: showLeading
              ? Container(
                  width: 60,
                  height: 60,
                  color: Colors.blue,
                )
              : null,
          trailing: showTrailing
              ? Container(
                  width: 60,
                  height: 60,
                  color: Colors.red,
                )
              : null,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: labelType,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.refresh),
              selectedIcon: Icon(Icons.read_more_outlined),
              label: Text('Hello'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.add_road),
              selectedIcon: Icon(Icons.add_road_outlined),
              label: Text('Match'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.emoji_events),
              selectedIcon: Icon(Icons.emoji_events_outlined),
              label: Text('Finals'),
            ),
          ],
        ),
        // Vertical Divider
        const VerticalDivider(thickness: 1, width: 1),
        // Match Selection
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: const SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("data")
                ],

              ),
            ),
          ),
        ),
      ],
    );
    }







      // Column(
      //   crossAxisAlignment: CrossAxisAlignment.stretch,
      //   children: [
      //     Expanded(
      //       child: FutureBuilder<List<dynamic>>(
      //         future: matches,
      //         builder: (context, snapshot) {
      //           if (snapshot.hasData) {
      //             // Filter and sort other matches
      //             var otherMatches = snapshot.data!.where((match) => !match['comp_level'].startsWith('f') && !match['comp_level'].startsWith('sf')).toList()
      //               ..sort((a, b) => a['match_number'].compareTo(b['match_number']));
      //             return _buildMatchList(otherMatches, Colors.yellow);
      //           } else {
      //             return const CircularProgressIndicator();
      //           }
      //         },
      //       ),
      //     ),
      //     Expanded(
      //       child: FutureBuilder<List<dynamic>>(
      //         future: matches,
      //         builder: (context, snapshot) {
      //           if (snapshot.hasData) {
      //             // Filter and sort finals matches
      //             var finalsMatches = snapshot.data!.where((match) => match['comp_level'].startsWith('f')).toList()
      //               ..sort((a, b) => a['match_number'].compareTo(b['match_number']));
      //             return _buildMatchList(finalsMatches, Colors.red);
      //           } else {
      //             return const CircularProgressIndicator();
      //           }
      //         },
      //       ),
      //     ),
      //     Expanded(
      //       child: FutureBuilder<List<dynamic>>(
      //         future: matches,
      //         builder: (context, snapshot) {
      //           if (snapshot.hasData) {
      //             // Filter and sort semifinals matches
      //             var semifinalsMatches = snapshot.data!.where((match) => match['comp_level'].startsWith('sf')).toList()
      //               ..sort((a, b) => a['match_number'].compareTo(b['match_number']));
      //             return _buildMatchList(semifinalsMatches, Colors.orange);
      //           } else {
      //             return const CircularProgressIndicator();
      //           }
      //         },
      //       ),
      //     ),
      //     const SizedBox(height: 10),
      //
      //     const SizedBox(height: 10),
      //   ],
      // )



  Widget _buildMatchList(List<dynamic> matches, Color buttonColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of columns
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 1.5, // Width is 1.5 times the height
      ),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        var match = matches[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Match(
                  eventKey: eventKeyController.text,
                  matchKey: match['key'],
                  allianceColor: Variables.allianceColor,
                  station: Variables.selectedStation,
                ),
              ),
            );
          },
          child: Text(
            '${match['match_number']}',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

class Variables {
  static String? eventKey;
  static String? allianceColor;
  static String? selectedStation;
  static String? matchKey;
  static String? matchType;
  static String? file;
}

// FutureBuilder<List<dynamic>>(
//   future: matches,
//   builder: (context, snapshot) {
//     if (snapshot.hasData) {
//       // Sort the matches by match_number
//       var sortedMatches = snapshot.data!.toList()
//         ..sort((a, b) => a['match_number'].compareTo(b['match_number']));
//       return Expanded(
//         child: GridView.builder(
//           padding: const EdgeInsets.all(8.0),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 3, // Number of columns
//             mainAxisSpacing: 8.0,
//             crossAxisSpacing: 8.0,
//             childAspectRatio: 1.5, // Width is 1.5 times the height
//           ),
//           itemCount: sortedMatches.length,
//           itemBuilder: (context, index) {
//             var match = sortedMatches[index];
//             Color buttonColor;
//             if (match['comp_level'].startsWith('sf')) {
//               buttonColor = Colors.orange; // Semi-Finals color
//             } else if (match['comp_level'].startsWith('f')) {
//               buttonColor = Colors.red; // Finals color
//             } else {
//               buttonColor = Colors.yellowAccent; // Default color for other matches
//             }
//             return ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: buttonColor,
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => Match(
//                       eventKey: eventKeyController.text,
//                       matchKey: match['key'],
//                       allianceColor: Variables.allianceColor,
//                       station: Variables.selectedStation,
//                     ),
//                   ),
//                 );
//               },
//               child: Text(
//                 '${match['match_number']}',
//                 textAlign: TextAlign.center,
//               ),
//             );
//           },
//         ),
//       );
//     } else {
//       return const CircularProgressIndicator();
//     }
//   },
// ),
