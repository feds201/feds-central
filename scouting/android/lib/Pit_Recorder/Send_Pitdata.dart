import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as Http;
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
    Http.Response response = await Http.get(Uri.parse('https://google.com'));
    return response.statusCode == 200;
  } catch (e) {
    print('Error: $e');
    return false;
  }
}

Future<bool> isServerConnected() async {
  var box = Hive.box('settings');
  String? ipAddress = box.get('ipAddress');
  try {
    String url = 'http://$ipAddress/alive';
    Http.Response response = await Http.get(
      Uri.parse(url),
    );
    print('Response status: ${response.statusCode}');
    return response.statusCode == 200;
  } catch (e) {
    print('Error: $e');
    return false;
  }
}

Future<bool> isPyintelConfigured() async {
  return await PluginStateManager()
      .getPluginState("intergrateWithPyintelScoutz");
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
                    color: Colors.blueAccent.shade100,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
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

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('settings');
    String? ipAddress = box.get('ipAddress');
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'Scout Ops Pool',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            buildChecklistItem('Data Validity', isDataValid()),
            FutureBuilder<bool>(
              future: isWifiConnected(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return buildChecklistItem("Connected to Wifi", false);
                } else {
                  return buildChecklistItem(
                      "Connected to Wifi", snapshot.data ?? false);
                }
              },
            ),
            FutureBuilder<bool>(
              future: isPyintelConfigured(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return buildChecklistItem("Configured Pyintel Scoutz", false);
                } else {
                  return buildChecklistItem(
                      "Configured Pyintel Scoutz", snapshot.data ?? false);
                }
              },
            ),
            FutureBuilder<bool>(
              future: isServerConnected(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return buildChecklistItem("Connected to Wifi", false);
                } else {
                  return buildChecklistItem(
                      "Connected to Server", snapshot.data ?? false);
                }
              },
            ),
            SizedBox(height: 20),
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
                    text: "Send Data",
                    color: Colors.grey,
                    icon: Icons.rocket,
                    onPressed: () {},
                  );
                } else {
                  return buildButton(
                    context: context,
                    text: "Send Data",
                    color: Color.fromARGB(255, 8, 168, 62),
                    icon: Icons.rocket,
                    onPressed: () async {
                      PitDataBase.LoadAll();
                      PitDataBase.PrintAll();
                      PitDataBase.SaveAll();
                      try {
                        String url = 'http://$ipAddress/send_pit_data';
                        Http.Response response = await Http.post(
                          Uri.parse(url),
                          headers: {
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode(PitDataBase.Export()),
                        );
                        print(response.statusCode);
                      } catch (e) {
                        print('Error: $e');
                      }
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
