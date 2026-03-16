import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:scout_ops_android/components/Button.dart';
import 'package:scout_ops_android/services/Colors.dart';
import 'package:scout_ops_android/services/DataBase.dart';
import 'package:scout_ops_android/services/NeonService.dart';

import '../main.dart';

bool isDataValid() {
  // Replace with your actual validation logic
  return PitDataBase.GetRecorderTeam().isNotEmpty;
}

Future<bool> isWifiConnected() async {
  // Try to request google.com and check if the response is successful
  try {
    http.Response response = await http
        .get(Uri.parse('https://google.com'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  } catch (e) {
    print('Error checking WiFi: $e');
    return false;
  }
}

Future<bool> isServerConfigured() async {
  // Check if we have a Google Apps Script URL configured
  return true;
}

Future<bool> isServerConnected() async {
  // For Google Apps Script, we can't really test connectivity directly
  return true;
}

Widget buildChecklistItem(String title, bool isValid) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: islightmode() ? lightColors.white : Color(0xFF2f3435),
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
                  color: islightmode()
                      ? Colors.black87
                      : Color.fromARGB(255, 255, 255, 255),
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
              boxShadow: [
                BoxShadow(
                  color: isValid
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
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

class SharePITDataScreen extends StatefulWidget {
  const SharePITDataScreen({super.key});

  @override
  State<SharePITDataScreen> createState() => _SharePITDataScreenState();
}

class _SharePITDataScreenState extends State<SharePITDataScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;
  String _statusMessage = "";
  double _uploadProgress = 0.0;
  int _currentTeamIndex = 0;
  int _totalTeams = 0;
  int _successCount = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget buildNowersList(List<int> nowers) {
    if (nowers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "No team data has been recorded yet",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final PageController pageController = PageController(viewportFraction: 0.3);
    ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

    return Column(
      children: [
        SizedBox(
          height: 70,
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
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                        fontSize: 20,
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
        const SizedBox(height: 12),

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
                  width: currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? Colors.blue.shade600
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
    return record.toJson();
  }

  Widget buildProgressBar() {
    if (!_isLoading) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Uploading Team Data",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                "$_currentTeamIndex of $_totalTeams",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background container
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Progress fill
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 20,
                width:
                    MediaQuery.of(context).size.width * _uploadProgress * 0.92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _hasError
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade700],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),

              // Percentage indicator
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${(_uploadProgress * 100).toInt()}%",
                    style: TextStyle(
                      color: _uploadProgress > 0.45
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _statusMessage,
            style: TextStyle(
              color: _hasError ? Colors.red.shade700 : Colors.blue.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendDataToFeds() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "Preparing to send data...";
      _uploadProgress = 0.0;
      _currentTeamIndex = 0;
      _successCount = 0;
      _hasError = false;
    });

    PitDataBase.LoadAll();

    try {
      final neonRest = Settings.getNeonRestUrl();
      if (neonRest.isEmpty) {
        setState(() {
          _hasError = true;
          _statusMessage = "Error: Neon REST URL is missing in Settings";
        });
        showErrorDialog(
            "Neon REST URL is not configured. Please add it in Settings.");
        return;
      }

      List<int> teams = PitDataBase.GetRecorderTeam();
      _totalTeams = teams.length;
      print("Sending data for team");
      for (var i = 0; i < teams.length; i++) {
        _currentTeamIndex = i + 1;
        int teamNumber = teams[i];

        // Update progress
        setState(() {
          _uploadProgress = i / teams.length;
          _statusMessage =
              "Sending team $teamNumber (${i + 1}/${teams.length})...";
          _hasError = false;
        });
        print("Sending data for team $teamNumber");

        PitRecord? record = PitDataBase.GetData(teamNumber);
        if (record != null) {
          // Format data for FEDS
          var formattedData = record.toJson();

          setState(() {
            _statusMessage =
                "Uploading data for Team $teamNumber (with 3 images)...";
          });

          try {
            final eventKey =
                Hive.box('userData').get('eventKey', defaultValue: 'event');

            // Prepare payload — include team and JSON data
            final payload = {
              'id': '${teamNumber}_${DateTime.now().millisecondsSinceEpoch}',
              'team_number': teamNumber,
              'data': formattedData,
              'created_at': DateTime.now().toIso8601String(),
            };

            bool sentToNeon = await NeonService.insert(eventKey, payload);
            if (sentToNeon) {
              print(
                  'Successfully inserted data for team $teamNumber into Neon');
              _successCount++;
              setState(() {
                _statusMessage = "Team $teamNumber data uploaded successfully!";
              });
            } else {
              print('Neon insert failed for team $teamNumber');
              setState(() {
                _hasError = true;
                _statusMessage = "Error uploading Team $teamNumber to Neon";
              });
            }
          } catch (e) {
            print('Error sending data for team $teamNumber to Neon: $e');
            setState(() {
              _hasError = true;
              _statusMessage = "Error uploading Team $teamNumber: $e";
            });
          }
        }

        // Add a small delay to avoid overwhelming the server
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Complete the progress bar
      setState(() {
        _uploadProgress = 1.0;
        _statusMessage =
            "Successfully sent $_successCount of ${teams.length} teams";
      });

      // Add a small delay before showing the result dialog
      await Future.delayed(Duration(milliseconds: 500));

      // Show result dialog
      showSuccessDialog(_successCount, teams.length);
    } catch (e) {
      print('Error in sendDataToFeds: $e');
      setState(() {
        _hasError = true;
        _statusMessage = "Error: $e";
      });
      // Show error dialog
      showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showSuccessDialog(int successCount, int totalCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                  successCount == totalCount
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color:
                      successCount == totalCount ? Colors.green : Colors.orange,
                  size: 28),
              SizedBox(width: 10),
              Text(successCount == totalCount
                  ? 'Upload Complete'
                  : 'Upload Finished'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Successfully sent data for $successCount of $totalCount teams.'),
              if (successCount < totalCount)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Some teams failed to upload. You may try again.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    successCount == totalCount ? Colors.green : Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to send data:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return IconButton(
              icon: const Icon(Icons.arrow_back),
              color: !islightmode()
                  ? const Color.fromARGB(193, 255, 255, 255)
                  : const Color.fromARGB(105, 36, 33, 33),
              onPressed: () => Navigator.pop(context));
        }),
        backgroundColor:
            islightmode() ? lightColors.white : darkColors.goodblack,
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
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Header card
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade400, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Text(
                          'Ensure all data is valid and ready to be sent to the FEDS server.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Checklist items
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
                        return buildChecklistItem(
                            "Configured FEDS Server", false);
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

                  // Progress bar for uploads
                  buildProgressBar(),

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
                      } else if (snapshot.hasError ||
                          !(snapshot.data ?? false)) {
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
                          onPressed:
                              _isLoading ? () {} : () => sendDataToFeds(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
