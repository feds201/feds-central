// import 'dart:convert';

// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'services/DataBase.dart';
// import 'components/SwipeCards.dart';
// import 'components/compactifier.dart';
// import 'Match_Pages/GeminiPrediction.dart';

// class LogsPage extends StatelessWidget {
//   const LogsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     List<String> matchData = MatchLogs.getLogs();
//     for (int i = 0; i < matchData.length; i++) {
//       print(parseAndLogJson(matchData[i]));
//     }

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: Center(
//           child: ShaderMask(
//               shaderCallback: (bounds) => const LinearGradient(
//                     colors: [Colors.red, Colors.blue],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ).createShader(bounds),
//               child: Text(
//                 'Match Logs',
//                 style: GoogleFonts.museoModerno(
//                   fontSize: 30,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.white,
//                 ),
//               )),
//         ),
//         centerTitle: true,
//         actions: <Widget>[
//           IconButton(
//             icon: const Icon(Icons.brightness_auto_outlined),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const GeminiPredictionPage(),
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.restore_from_trash_rounded),
//             onPressed: () {
//               MatchLogs.clearLogs();
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => const LogsPage(),
//                     fullscreenDialog: true),
//               );
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         scrollDirection: Axis.vertical,
//         child: CarouselSlider(
//           items: [
//             for (int i = 0; i < matchData.length; i++)
//               MatchCard(
//                 matchData: matchData[i].toString(),
//                 teamNumber: parseAndLogJson(matchData[i])[4],
//                 eventName: parseAndLogJson(matchData[i])[0],
//                 allianceColor: parseAndLogJson(matchData[i])[1],
//                 selectedStation: parseAndLogJson(matchData[i])[2],
//                 matchKey: parseAndLogJson(matchData[i])[3],
//               )
//           ],
//           options: CarouselOptions(
//             height: MediaQuery.of(context).size.height * .8,
//             enlargeFactor: 1,
//             aspectRatio: 4 / 3,
//             viewportFraction: 0.85,
//             initialPage: 0,
//             enableInfiniteScroll: false,
//             reverse: false,
//             autoPlay: false,
//             autoPlayInterval: const Duration(seconds: 3),
//             autoPlayAnimationDuration: const Duration(milliseconds: 200),
//             autoPlayCurve: Curves.easeInOutQuad,
//             enlargeCenterPage: true,
//             scrollDirection: Axis.horizontal,
//           ),
//         ),
//       ),
//     );
//   }

//   List<String> parseAndLogJson(String jsonString) {
//     try {
//       String correctedJsonString = correctJsonFormat(jsonString);
//       Map<String, dynamic> jsonObject = jsonDecode(correctedJsonString);
//       return [
//         jsonObject['TypeseventKey'],
//         jsonObject['TypesallianceColor'],
//         jsonObject['TypesselectedStation'],
//         jsonObject['TypesmatchKey'],
//         jsonObject['Typesteam']
//       ];
//     } catch (e) {
//       return [('Error: $e')];
//     }
//   }
// }
