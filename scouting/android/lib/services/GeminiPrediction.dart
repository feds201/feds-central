import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'GeminiService.dart';

class GeminiPredictionPage extends StatefulWidget {
  const GeminiPredictionPage({super.key});

  @override
  _GeminiPredictionPageState createState() => _GeminiPredictionPageState();
}

class _GeminiPredictionPageState extends State<GeminiPredictionPage> {
  bool isLoading = true;
  Map<String, dynamic>? predictions;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchPredictions();
  }

  Future<void> fetchPredictions() async {
    try {
      // Replace with the actual input data for predictions
      Map<String, dynamic> inputData = {
        'eventKey': '2025FRC',
        'teamData': [
          {'teamNumber': 123, 'performance': 85},
          {'teamNumber': 456, 'performance': 90},
          // Add more team data
        ],
      };

      final result = await GeminiService.getPredictions(inputData.toString());
      setState(() {
        predictions = result as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gemini Prediction',
          style: GoogleFonts.museoModerno(fontSize: 25, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage.isNotEmpty
                ? Text(
                    'Error: $errorMessage',
                    style: GoogleFonts.museoModerno(
                        fontSize: 20, color: Colors.red),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Prediction Results',
                        style: GoogleFonts.museoModerno(
                            fontSize: 30, color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Winning Team: ${predictions?['winningTeam'] ?? 'N/A'}',
                        style: GoogleFonts.museoModerno(
                            fontSize: 20, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Top 3 Teams to Collaborate:',
                        style: GoogleFonts.museoModerno(
                            fontSize: 20, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      ...?predictions?['topTeams']?.map((team) => Text(
                            team,
                            style: GoogleFonts.museoModerno(
                                fontSize: 18, color: Colors.black),
                          )),
                    ],
                  ),
      ),
    );
  }
}
