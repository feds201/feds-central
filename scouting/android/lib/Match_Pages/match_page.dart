import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../components/DataBase.dart';
import '../components/nav.dart';
import 'match.dart';
import 'match_Selection.dart';

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
  int _selectedMatchType = 0; // New state variable for NavigationRail
  String eventKey = '';

  @override
  void initState() {
    super.initState();
    try {
      eventKey = LocalDataBase.getData(Types.eventKey) ?? '';
      eventKeyController.text = eventKey;
      matches = readJson();
      matches?.then((data) {
        developer.log(jsonEncode(data)); // Print the data once it is fetched
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Match'),
        backgroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Refresh',
            onPressed: () {
              isLoading = true;
              setState(() {
                matches = null;
                LocalDataBase.putData(Types.eventFile, null);
                LocalDataBase.putData(Types.eventKey, null);
                eventKeyController.text = '';
                LocalDataBase.putData(Types.allianceColor, null);
                LocalDataBase.putData(Types.selectedStation, null);
                LocalDataBase.putData(Types.matchFile, null);
                LocalDataBase.putData(Types.matchKey, null);
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
        currentIndex: _selectedIndex.clamp(
            0, 1), // Ensure currentIndex is within valid range
        selectedItemColor: Colors.red,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget matchPage(BuildContext context, int selectedIndex) {
    return selectedIndex == 0
        ? setup(context)
        : FutureBuilder<List<dynamic>>(
            future: matches,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No data available!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Please ensure you are connected to the internet.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Verify the event key and try again.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Check the API key in the settings page.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return matchSelection(context, _selectedMatchType, (int index) {
                  setState(() {
                    _selectedMatchType = index;
                  });
                }, jsonEncode(snapshot.data));
              }
            },
          );
  }

  void prepopulateData() {
    try {
      var data = Hive.box("matchData").get("matches", defaultValue: null);
      LocalDataBase.putData(Types.eventFile, data.toString());
      LocalDataBase.putData(Types.eventKey, data[0]['event_key']);
      eventKeyController.text = LocalDataBase.getData(Types.eventKey);
      writeJson(data);
      setState(() {
        matches = readJson();
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load data');
      }
      setState(() {
        isLoading = true;
      });
    }
  }

  Future<void> prepopulateDataServer() async {
    var box = Hive.box('settings');
    String ipAddress = box.get('ipAddress', defaultValue: '');
    String url = 'http://$ipAddress/get_event_file';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        developer.log(data[0]['event_key']);
        Hive.box('matchData').put('matches', (data));
        LocalDataBase.putData(Types.eventFile, data.toString());
        LocalDataBase.putData(Types.eventKey, data[0]['event_key']);
        eventKeyController.text = LocalDataBase.getData(Types.eventKey);
        writeJson(data);
        setState(() {
          matches = readJson();
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load data');
        print(e);
      }
      setState(() {
        isLoading = true;
      });
    }
  }

  List<Widget> modules(BuildContext context) {
    return [
      const SizedBox(height: 10),
      TextField(
        controller: eventKeyController,
        decoration: InputDecoration(
          labelText: 'Match Event Key (e.g. 2024brbr)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      const SizedBox(height: 10),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
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
                    minimumSize:
                        Size(MediaQuery.of(context).size.width / 2, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () => getData(eventKeyController.text),
                  child: const Text('Load Event'),
                ),
              ],
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: isLoading ? Colors.grey : Colors.red,
                  ),
                  onPressed: () {
                    prepopulateData();
                  },
                  onLongPress: () {
                    prepopulateDataServer();
                  },
                  child: const Text('Use Local'),
                ),
              ],
            ),
          ],
        ),
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
                  backgroundColor:
                      LocalDataBase.getData(Types.allianceColor) == 'Red'
                          ? Colors.red
                          : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.red)),
                ),
                onPressed: () {
                  setState(() {
                    LocalDataBase.putData(Types.allianceColor, 'Red');
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
                  backgroundColor:
                      LocalDataBase.getData(Types.allianceColor) == 'Blue'
                          ? Colors.blue
                          : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    LocalDataBase.putData(Types.allianceColor, 'Blue');
                  });
                },
                child: const Text('Blue'),
              ),
            ),
          ),
        ],
      ),
      if (LocalDataBase.getData(Types.allianceColor) == "Red") ...[
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
                        LocalDataBase.putData(Types.selectedStation, 'R1');
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            LocalDataBase.getData(Types.selectedStation) == "R1"
                                ? Colors.red
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R1'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        LocalDataBase.putData(Types.selectedStation, 'R2');
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            LocalDataBase.getData(Types.selectedStation) == "R2"
                                ? Colors.red
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R2'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        LocalDataBase.putData(Types.selectedStation, 'R3');
                      });
                    },
                    //change the color when selected

                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            LocalDataBase.getData(Types.selectedStation) == "R3"
                                ? Colors.red
                                : Colors.grey,
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
                    'assets/${LocalDataBase.getData(Types.allianceColor)}Alliance.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                  ),
                ],
              ),
            )
          ],
        ),
      ] else if (LocalDataBase.getData(Types.allianceColor) == "Blue") ...[
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
                        LocalDataBase.putData(Types.selectedStation, "B1");
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            LocalDataBase.getData(Types.selectedStation) == "B1"
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('B1'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        LocalDataBase.putData(Types.selectedStation, "B2");
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            LocalDataBase.getData(Types.selectedStation) == "B2"
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('B2'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        LocalDataBase.putData(Types.selectedStation, "B3");
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            LocalDataBase.getData(Types.selectedStation) == "B3"
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('B3'),
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
                    'assets/${LocalDataBase.getData(Types.allianceColor)}Alliance.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                  ),
                ],
              ),
            )
          ],
        ),
      ],
    ];
  }

  void getData(String eventKey) async {
    setState(() {
      isLoading = true;
    });
    var ApiKey = Settings.getApiKey();
    print(ApiKey);
    var headers = {
      'X-TBA-Auth-Key': ApiKey,
    };
    var response = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/matches'),
        headers: headers);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      LocalDataBase.putData(Types.eventFile, data.toString());
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
}
