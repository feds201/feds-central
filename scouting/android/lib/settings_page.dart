import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scouting_app/main.dart';

import 'services/DataBase.dart';
import 'components/MatchSelection.dart';
import 'components/ScoutersList.dart';
import 'components/nav.dart';
import 'components/qr_code_scanner_page.dart';
import 'package:http/http.dart' as http;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  String version = '3.1.1.1';
  bool isLocationGranted = false;
  bool isBluetoothGranted = false;
  bool isNearbyDevicesGranted = false;
  bool isCameraGranted = false;
  bool isDarkMode = true;
  bool isLoading = false;
  bool isjson = true;
  TextEditingController eventKeyController = TextEditingController();
  String ApiKey = Hive.box('settings').get('ApiKey', defaultValue: '');

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
    Settings.setApiKey(ApiKey);
  }

  Future<void> _checkInitialPermissions() async {
    var locationStatus = await Permission.location.status;
    var bluetoothStatus = await Permission.bluetooth.status;
    var nearbyDevicesStatus = await Permission.bluetoothAdvertise.status;
    var cameraStatus = await Permission.camera.status;

    setState(() {
      isLocationGranted = locationStatus.isGranted;
      isBluetoothGranted = bluetoothStatus.isGranted;
      isNearbyDevicesGranted = nearbyDevicesStatus.isGranted;
      isCameraGranted = cameraStatus.isGranted;
    });
  }

  Future<void> _requestPermission(Permission permission, bool currentValue,
      Function(bool) onChanged) async {
    if (currentValue) {
      if (await permission.request().isGranted) {
        onChanged(true);
      } else {
        onChanged(false);
      }
    } else {
      onChanged(false);
    }
  }

  Future<void> getData(String eventKey) async {
    setState(() {
      isLoading = true;
    });

    print("Getting Data");
    print(eventKey);
    var ApiKey = Settings.getApiKey();
    var headers = {
      'X-TBA-Auth-Key': ApiKey,
    };
    var responseForMatchData = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/matches'),
        headers: headers);

    if (responseForMatchData.statusCode == 200) {
      if (kDebugMode) {
        print('Success');
      }
      Hive.box('matchData')
          .put('matches', jsonDecode(responseForMatchData.body));

      print(Hive.box('matchData').get('matches'));
    }

    var responseForPitData = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/teams'),
        headers: headers);

    if (responseForPitData.statusCode == 200) {
      if (kDebugMode) {
        print('Success');
      }
      Hive.box('pitData').put('teams', (responseForPitData.body));
      setState(() {
        isLoading = false;
      });
    } else {
      if (kDebugMode) {
        print('Error: ${responseForPitData.statusCode}');
        setState(() {
          isLoading = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white), // Error icon
                SizedBox(width: 10), // Spacing
                Expanded(
                  child: Text(
                    "Bro... maybe, just maybe, check your API Key and Event Key before blaming the universe for my app not working. Just a thought. 🙃",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating, // Floating style
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: "Retry",
              textColor: Colors.white,
              onPressed: () {
                // Add retry logic here
              },
            ),
          ),
        );
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    eventKeyController.text =
        Hive.box('userData').get('eventKey', defaultValue: '');
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'Settings',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScouterList(),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(
                left: 0,
                right: 0,
              ),
              width: double.infinity,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TextField(
                        controller: TextEditingController()
                          ..text = Hive.box('settings')
                              .get('ApiKey', defaultValue: ''),
                        decoration: InputDecoration(
                          labelText: 'BlueAlliance API Key',
                          labelStyle: GoogleFonts.museoModerno(fontSize: 15, color: islightmode() ? Colors.black : Colors.white),
                          hintText: 'Enter your API Key',
                          hintStyle: GoogleFonts.museoModerno(fontSize: 15, color: islightmode() ? Colors.black : Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: islightmode() ? Colors.black : Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: islightmode() ? Colors.black : Colors.white),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            color: islightmode() ? Colors.black : Colors.white,
                            onPressed: () async {
                              final qrCode = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const QRCodeScannerPage(),
                                    fullscreenDialog: true),
                              );
                              if (qrCode != null) {
                                setState(() {
                                  ApiKey = qrCode;
                                  Hive.box('settings').put('ApiKey', qrCode);
                                  Settings.setApiKey(qrCode);
                                });
                              }
                            },
                          ),
                        ),
                        style: GoogleFonts.museoModerno(fontSize: 18),
                        onSubmitted: (String value) {
                          Hive.box('settings').put('ApiKey', value);
                          Settings.setApiKey(value);
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: eventKeyController,
                        onChanged: (String value) {
                          Hive.box('userData').put('eventKey', value);
                        },
                        decoration: InputDecoration(
                          labelText: 'Match Event Key (e.g. 2024isde4)',
                          labelStyle: GoogleFonts.museoModerno(fontSize: 15, color: islightmode() ? Colors.black : Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: islightmode() ? Colors.black : Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: islightmode() ? Colors.black : Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ]),
            ), // Scouter Name and API Key

            const SizedBox(height: 0),
            MatchSelection(
                onAllianceSelected: (String? alliance) {
                  setState(() {
                    Hive.box('userData').put('alliance', alliance);
                  });
                },
                onPositionSelected: (String? position) {
                  setState(() {
                    Hive.box('userData').put('position', position);
                  });
                },
                initAlliance:
                    Hive.box('userData').get('alliance', defaultValue: "Red"),
                initPosition: Hive.box('userData').get('position',
                    defaultValue:
                        '1') //Takeout the first letter of the alliance and add it to the position
                ), // Alliance and Position
            const SizedBox(height: 10),
            Center(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color:
                              isLoading ? Colors.redAccent : Colors.green[300],
                          border: Border.all(
                            color: isLoading ? Colors.red : Colors.green,
                            width: 3,
                          ),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              Size(MediaQuery.of(context).size.width / 2, 50),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Colors.blue,
                              width: 3,
                            ),
                          ),
                        ),
                        onPressed: () => getData(eventKeyController.text),
                        child: Text(
                          'Load Event',
                          style: GoogleFonts.museoModerno(
                              fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  )),
            ),

            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(
                left: 10,
                right: 10,
              ),
              width: double.infinity,
              child: Column(
                children: [
                  // Switch for Location permission

                  const SizedBox(height: 10),
                  SwitchListTile(
                    tileColor: const Color.fromARGB(97, 159, 157, 157),
                    contentPadding: const EdgeInsets.only(left: 20, right: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text("Location",
                        style: GoogleFonts.museoModerno(fontSize: 20)),
                    thumbIcon: thumbIcon,
                    value: isLocationGranted,
                    onChanged: (bool value) {
                      _requestPermission(Permission.location, value,
                          (newValue) {
                        setState(() {
                          isLocationGranted = newValue;
                        });
                      });
                    },
                    activeTrackColor: const Color.fromARGB(255, 11, 243, 11),
                    activeColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 10),
                  // Switch for Bluetooth permission
                  SwitchListTile(
                    tileColor: const Color.fromARGB(97, 159, 157, 157),
                    contentPadding: const EdgeInsets.only(left: 20, right: 20),
                    thumbIcon: thumbIcon,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text("Bluetooth",
                        style: GoogleFonts.museoModerno(fontSize: 20)),
                    value: isBluetoothGranted,
                    onChanged: (bool value) {
                      _requestPermission(Permission.bluetooth, value,
                          (newValue) {
                        setState(() {
                          isBluetoothGranted = newValue;
                        });
                      });
                    },
                    activeTrackColor: const Color.fromARGB(255, 11, 243, 11),
                    activeColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 10),
                  // Switch for Nearby Devices permission
                  SwitchListTile(
                    tileColor: const Color.fromARGB(97, 159, 157, 157),
                    contentPadding: const EdgeInsets.only(left: 20, right: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text("Nearby Devices",
                        style: GoogleFonts.museoModerno(fontSize: 20)),
                    thumbIcon: thumbIcon,
                    value: isNearbyDevicesGranted,
                    onChanged: (bool value) {
                      _requestPermission(Permission.bluetoothAdvertise, value,
                          (newValue) {
                        setState(() {
                          isNearbyDevicesGranted = newValue;
                        });
                      });
                    },
                    activeTrackColor: const Color.fromARGB(255, 11, 243, 11),
                    activeColor: const Color.fromARGB(255, 255, 255, 255),
                  ),

                  const SizedBox(height: 10),

                  SwitchListTile(
                    tileColor: const Color.fromARGB(97, 159, 157, 157),
                    contentPadding: const EdgeInsets.only(left: 20, right: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text("Camera",
                        style: GoogleFonts.museoModerno(fontSize: 20)),
                    thumbIcon: thumbIcon,
                    value: isCameraGranted,
                    onChanged: (bool value) {
                      _requestPermission(Permission.camera, value, (newValue) {
                        setState(() {
                          isCameraGranted = newValue;
                        });
                      });
                    },
                    activeTrackColor: const Color.fromARGB(255, 11, 243, 11),
                    activeColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 10),
                  // ChoiceChip(
                  //   label: Center(
                  //     child: Text(
                  //       isjson ? "Json" : "Csv",
                  //       style: GoogleFonts.museoModerno(
                  //           fontSize: 25, color: Colors.white),
                  //     ),
                  //   ),
                  //   selectedColor: const Color.fromARGB(255, 25, 89, 241),
                  //   selected: true,
                  //   showCheckmark: false,
                  //   side: const BorderSide(color: Colors.black),
                  //   onSelected: (bool selected) {
                  //     setState(() {
                  //       isjson = !isjson;
                  //     });
                  //     Hive.box('settings').put('isjson', isjson);
                  //   },
                  // ),
                ],
              ),
            ), // Permission Switches

            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(left: 10, right: 10),
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Eject Match',
                              style: GoogleFonts.museoModerno(
                                  fontSize: 25, color: Colors.white),
                            ),
                          ),
                          selectedColor: const Color.fromARGB(255, 18, 54, 133),
                          selected: true,
                          side: const BorderSide(color: Colors.black),
                          showCheckmark: false,
                          onSelected: (bool selected) {
                            setState(() {
                              Hive.box('matchData').delete('matches');
                              print('Data Cleared');
                              developer.log(
                                  Hive.box('userData').get('scouterName',
                                          defaultValue: '') +
                                      ' cleared all data',
                                  name: 'Data Cleared');
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Clear Data',
                              style: GoogleFonts.museoModerno(
                                  fontSize: 25, color: Colors.white),
                            ),
                          ),
                          selectedColor: const Color.fromARGB(255, 25, 89, 241),
                          selected: true,
                          showCheckmark: false,
                          side: const BorderSide(color: Colors.black),
                          onSelected: (bool selected) {
                            setState(() {
                              Hive.box('userData').deleteAll;
                              Hive.box('matchData').deleteAll;
                              Hive.box('settings').deleteAll;
                              Hive.box('pitData').deleteAll;
                              Hive.box('matchData').delete('matches');
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              'Check for Updates',
                              style: GoogleFonts.museoModerno(
                                  fontSize: 25, color: Colors.white),
                            ),
                          ),
                          selectedColor: const Color.fromARGB(255, 25, 89, 241),
                          selected: true,
                          showCheckmark: false,
                          side: const BorderSide(color: Colors.black),
                          onSelected: (bool selected) {
                            http.Request(
                              "GET",
                              Uri.parse(
                                  "https://api.github.com/repos/feds201/Scout-Ops-Android/releases/latest"),
                            ).send().then((response) {
                              response.stream
                                  .bytesToString()
                                  .then((body) async {
                                final jsonData = jsonDecode(body);
                                String remoteTag = jsonData[
                                    'tag_name']; // e.g. "Version-2.0.1.3"
                                if (remoteTag.startsWith("Version-")) {
                                  remoteTag =
                                      remoteTag.substring("Version-".length);
                                }
                                List<int> localParts =
                                    version.split('.').map(int.parse).toList();
                                List<int> remoteParts = remoteTag
                                    .split('.')
                                    .map(int.parse)
                                    .toList();
                                print("Local Nav: $localParts");
                                print("Remote Nav: $remoteParts");
                                int compare = 0;
                                for (int i = 0; i < localParts.length; i++) {
                                  if (i >= remoteParts.length) break;
                                  if (remoteParts[i] > localParts[i]) {
                                    compare = 1;
                                    break;
                                  } else if (remoteParts[i] < localParts[i]) {
                                    compare = -1;
                                    break;
                                  }
                                }
                                if (compare > 0) {
                                  print("Update Available");
                                  print(jsonData["assets"][0]
                                      ["browser_download_url"]);

                                  InstallApk(await downloadApk(
                                      jsonData["assets"][0]
                                          ["browser_download_url"],
                                      remoteTag));
                                } else {
                                  print("No Update Available");
                                }
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ), // Load Match, Eject Match, Clear Data
          ],
        ),
      ),
    );
  }
}

final WidgetStateProperty<Icon?> thumbIcon =
    WidgetStateProperty.resolveWith<Icon?>(
  (Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return const Icon(Icons.check);
    }
    return const Icon(Icons.close);
  },
);

Future<String> downloadApk(String apkUrl, String version) async {
  var response = await http.get(Uri.parse(apkUrl));

  if (response.statusCode == 200) {
    var bytes = response.bodyBytes;

    var dir = await getTemporaryDirectory();

    var filePath = dir.path + '/ScoutOps_$version.apk';

    File file = File(filePath);

    await file.writeAsBytes(bytes);
    return filePath;
  } else {
    print("Error: ${response.statusCode}");
    return "";
  }
}

void InstallApk(String filePath) async {
  Process.run('adb', ['install', filePath]).then((result) {
    if (result.exitCode == 0) {
      print("APK installed successfully.");
    } else {
      print("Error installing APK: ${result.stderr}");
    }
  });
}
