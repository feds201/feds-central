import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scouting_app/Plugins/plugin_state_manager.dart';
import 'package:scouting_app/components/Button.dart';
import 'package:scouting_app/services/DataBase.dart';

bool isDataValid() {
  // Replace with your actual validation logic
  return PitDataBase.GetRecorderTeam().isNotEmpty;
}

Future<bool> isWifiConnected() async {
  // Try to request google.com and check if the response is successful
  try {
    http.Response response = await http.get(Uri.parse('https://google.com'));
    return response.statusCode == 200;
  } catch (e) {
    print('Error: $e');
    return false;
  }
}

Future<bool> isServerConfigured() async {
  // Check if we have a Google Apps Script URL configured
  var box = Hive.box('settings');
  String? scriptUrl = box.get('fedsScriptUrl');
  return scriptUrl != null && scriptUrl.isNotEmpty;
}

Future<bool> isServerConnected() async {
  // For Google Apps Script, we can't really test connectivity directly
  // We'll just check if the URL is valid
  try {
    var box = Hive.box('settings');
    String? scriptUrl = box.get('fedsScriptUrl');
    if (scriptUrl == null || !scriptUrl.contains('script.google.com')) {
      return false;
    }
    // We'll assume the server is available if we have a valid URL
    return true;
  } catch (e) {
    print('Error: $e');
    return false;
  }
}

Widget buildChecklistItem(String title, bool isValid) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with animation
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (widget, animation) {
              return ScaleTransition(scale: animation, child: widget);
            },
            child: Icon(
              isValid ? Icons.check_circle : Icons.cancel,
              key: ValueKey(isValid),
              color: isValid ? Colors.green : Colors.red,
              size: 30,
            ),
          ),

          // Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title,
                style: GoogleFonts.museoModerno(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Valid/Invalid Label with Gradient
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isValid
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isValid ? 'Valid' : 'Invalid',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SharePITDataScreen extends StatelessWidget {
  const SharePITDataScreen({super.key});

  Widget buildNowersList(List<int> nowers) {
    final PageController pageController = PageController(viewportFraction: 0.3);
    ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

    return Column(
      children: [
        SizedBox(
          height: 60,
          child: PageView.builder(
            controller: pageController,
            scrollDirection: Axis.horizontal,
            itemCount: nowers.length,
            onPageChanged: (index) {
              currentIndex.value = index;
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      nowers[index].toString(),
                      style: GoogleFonts.museoModerno(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Bullet Indicator
        ValueListenableBuilder<int>(
          valueListenable: currentIndex,
          builder: (context, currentIndex, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(nowers.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentIndex == index ? 16 : 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? Colors.blueAccent
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  // Convert PitRecord to FEDS Scouting Server format
  Map<String, dynamic> formatPitDataForFEDS(PitRecord record) {
    // Map scoreType to appropriate format
    String scoreLocation = "";
    if (record.scoreType.contains("L1"))
      scoreLocation = "L1 - 1 piece";
    else if (record.scoreType.contains("L2"))
      scoreLocation = "L2 - 3 pieces";
    else if (record.scoreType.contains("L3"))
      scoreLocation = "L3 - 5 pieces";
    else if (record.scoreType.contains("L4")) scoreLocation = "L4 - 7 pieces";

    // Determine climb type
    String endgame = "Park";
    if (record.climbType.contains("Deep")) {
      endgame = "Deep Climb";
    } else if (record.climbType.contains("Shallow")) {
      endgame = "Shallow Climb";
    }

    return {
      "team": record.teamNumber.toString(),
      "drivetrain": record.driveTrainType,
      "auton": record.autonType,
      "leaveAuton": "Yes", // Default to yes if they have auton
      "scoreLocation": scoreLocation,
      "scoreType": record.scoreType.join(", "),
      "intakeCoral": record.intake,
      "scoreCoral":
          record.scoreObject.isNotEmpty ? record.scoreObject.join(", ") : "L1",
      "intakeAlgae": "Can do ALL", // Default
      "scoreAlgae": "Processor", // Default
      "endgame": endgame,
      "botImage": "" // Placeholder for image
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'FEDS Scout Ops',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FEDS Scouting Server Integration',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.museoModerno(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              buildChecklistItem('Data Validity', isDataValid()),
              FutureBuilder<bool>(
                future: isWifiConnected(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return buildChecklistItem("Connected to Wifi", false);
                  } else {
                    return buildChecklistItem(
                        "Connected to Wifi", snapshot.data ?? false);
                  }
                },
              ),
              FutureBuilder<bool>(
                future: isServerConfigured(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return buildChecklistItem("Configured FEDS Server", false);
                  } else {
                    return buildChecklistItem(
                        "Configured FEDS Server", snapshot.data ?? false);
                  }
                },
              ),
              FutureBuilder<bool>(
                future: isServerConnected(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return buildChecklistItem("Server Available", false);
                  } else {
                    return buildChecklistItem(
                        "Server Available", snapshot.data ?? false);
                  }
                },
              ),
              SizedBox(height: 20),

              // Teams section header
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.groups, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(
                      'Teams to Submit:',
                      style: GoogleFonts.museoModerno(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              buildNowersList(PitDataBase.GetRecorderTeam()),
              SizedBox(height: 20),
              FutureBuilder<bool>(
                future: Future.wait([
                  isServerConnected(),
                  Future.value(isDataValid()),
                  isWifiConnected()
                ]).then((results) => results.every((result) => result)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || !(snapshot.data ?? false)) {
                    return buildButton(
                      context: context,
                      text: "Send Data to FEDS",
                      color: Colors.grey,
                      icon: Icons.cloud_upload,
                      onPressed: () {},
                    );
                  } else {
                    return buildButton(
                      context: context,
                      text: "Send Data to FEDS",
                      color: Color.fromARGB(255, 8, 168, 62),
                      icon: Icons.cloud_upload,
                      onPressed: () async {
                        PitDataBase.LoadAll();
                        // Show loading dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );

                        try {
                          var box = Hive.box('settings');
                          String scriptUrl = box.get('fedsScriptUrl') ??
                              'https://script.google.com/macros/s/AKfycbyebARML-RoGQGZ7ugmVNGvuwtGhyh5it1LEeNWDaiVQPsbA1mD8pSZcDO9Vk2UryIxTg/exec';

                          List<int> teams = PitDataBase.GetRecorderTeam();
                          int successCount = 0;

                          for (var teamNumber in teams) {
                            PitRecord? record = PitDataBase.GetData(teamNumber);
                            if (record != null) {
                              // Format data for FEDS
                              var formattedData = formatPitDataForFEDS(record);

                              // Send to Google Apps Script
                              var headers = {
                                'Content-Type': 'application/json'
                              };
                              var request =
                                  http.Request('POST', Uri.parse(scriptUrl));
                              request.body = jsonEncode(formattedData);
                              request.headers.addAll(headers);

                              http.StreamedResponse response =
                                  await request.send();

                              if (response.statusCode == 200) {
                                print(
                                    'Successfully sent data for team $teamNumber');
                                successCount++;
                              } else {
                                print(
                                    'Failed to send data for team $teamNumber: ${response.reasonPhrase}');
                              }
                            }
                          }

                          // Pop loading dialog
                          Navigator.of(context).pop();

                          // Show result dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Upload Results'),
                                content: Text(
                                    'Successfully sent data for $successCount of ${teams.length} teams.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        } catch (e) {
                          // Pop loading dialog
                          Navigator.of(context).pop();

                          // Show error dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Error'),
                                content: Text('Failed to send data: $e'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
