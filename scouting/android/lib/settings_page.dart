import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import 'components/DataBase.dart';
import 'components/MatchSelection.dart';
import 'components/ScoutersList.dart';
import 'components/localmatchLoader.dart';
import 'components/nav.dart';
import 'components/qr_code_scanner_page.dart';
import 'Match_Pages/match.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool isLocationGranted = false;
  bool isBluetoothGranted = false;
  bool isNearbyDevicesGranted = false;
  bool isCameraGranted = false;
  bool isDarkMode = true;
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

  @override
  Widget build(BuildContext context) {
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
                      // TextField(
                      //   controller: TextEditingController()
                      //     ..text = Hive.box('userData')
                      //         .get('scouterName', defaultValue: ''),
                      //   decoration: InputDecoration(
                      //     labelText: 'Scouter Name',
                      //     labelStyle: GoogleFonts.museoModerno(fontSize: 15),
                      //     hintText: 'Enter your name',
                      //     hintStyle: GoogleFonts.museoModerno(fontSize: 15),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10),
                      //       borderSide: const BorderSide(color: Colors.black),
                      //     ),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10),
                      //       borderSide: const BorderSide(color: Colors.black),
                      //     ),
                      //   ),
                      //   style: GoogleFonts.museoModerno(fontSize: 18),
                      //   onSubmitted: (String value) {
                      //     Hive.box('userData').put('scouterName', value);
                      //   },
                      // ),
                      // const SizedBox(height: 10),
                      TextField(
                        controller: TextEditingController()
                          ..text = Hive.box('settings')
                              .get('ApiKey', defaultValue: ''),
                        decoration: InputDecoration(
                          labelText: 'BlueAlliance API Key',
                          labelStyle: GoogleFonts.museoModerno(fontSize: 15),
                          hintText: 'Enter your API Key',
                          hintStyle: GoogleFonts.museoModerno(fontSize: 15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
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
                    ],
                  ),
                ),
              ]),
            ), // Scouter Name and API Key

            const SizedBox(height: 0),
            MatchSelection(
                onAllianceSelected: (String? alliance) {
                  setState(() {
                    Hive.box('userData').put('alliance', alliance);
                    LocalDataBase.putData(Types.allianceColor, alliance);
                  });
                },
                onPositionSelected: (String? position) {
                  setState(() {
                    Hive.box('userData').put('position', position);
                    LocalDataBase.putData(
                        Types.selectedStation,
                        ((Hive.box('userData').get('alliance') == "Red")
                                ? "R"
                                : "B") +
                            position!);
                  });
                },
                initAlliance:
                    Hive.box('userData').get('alliance', defaultValue: "Red"),
                initPosition: Hive.box('userData').get('position',
                    defaultValue:
                        '1') //Takeout the first letter of the alliance and add it to the position
                ), // Alliance and Position
            const SizedBox(height: 10),
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
                ],
              ),
            ), // Permission Switches
            const SizedBox(height: 10),
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
                          iconTheme: const IconThemeData(color: Colors.white),
                          label: Center(
                            child: Text(
                              'Load Match',
                              style: GoogleFonts.museoModerno(
                                  fontSize: 25, color: Colors.white),
                            ),
                          ),
                          selectedColor: const Color.fromARGB(255, 18, 54, 133),
                          selected: true,
                          showCheckmark: false,
                          side: const BorderSide(color: Colors.black),
                          onSelected: (bool selected) {
                            setState(() {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const localmatchLoader(),
                                    fullscreenDialog: true),
                              );
                            });
                          },
                        ),
                      ),
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
                              LocalDataBase.clearData();
                              MatchLogs.clearLogs();
                              Hive.box('matchData').delete('matches');
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
