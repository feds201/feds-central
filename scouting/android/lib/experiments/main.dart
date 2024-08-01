import 'dart:convert';

void parseAndLogJson(String jsonString) {
  try {
    List<dynamic> jsonArray = jsonDecode(jsonString);

    for (var jsonObject in jsonArray) {
      print("Event Key: ${jsonObject['Types.eventKey']}");
      print("Alliance Color: ${jsonObject['Types.allianceColor']}");
      print("Selected Station: ${jsonObject['Types.selectedStation']}");
      print("Match Key: ${jsonObject['Types.matchKey']}");
      print("Team: ${jsonObject['Types.team']}");
      // Add more fields as needed
    }
  } catch (e) {
    print('Error: $e');
  }
}

void main() {
  String jsonString = '''
  [
    {
      "Types.eventKey": "2024cmptx",
      "Types.allianceColor": "Red",
      "Types.selectedStation": "R1",
      "Types.matchKey": "2024cmptx_sf1m1",
      "Types.team": 4613,
      "AutoType.AmpPlacement": 1,
      "AutoType.Speaker": 1,
      "AutoType.Trap": 1,
      "AutoType.StartPosition": {"dx": 266.9047619047619, "dy": 127.47619047619048},
      "AutoType.AutonRating": 5,
      "AutoType.Chip1": true,
      "AutoType.Chip2": true,
      "AutoType.Chip3": false,
      "TeleType.GroundPickUp": 1,
      "TeleType.SourcePickUp": 1,
      "TeleType.SpeakerNotes": 1,
      "TeleType.AmpPlacement": 1,
      "TeleType.TrapPlacement": 1,
      "TeleType.AmplifiedSpeakerNotes": 0,
      "TeleType.CoOpBonus": true,
      "TeleType.Assists": 1,
      "EndgameType.endLocation": {"dx": 266.9047619047619, "dy": 127.47619047619048},
      "EndgameType.climbed": true,
      "EndgameType.harmony": true,
      "EndgameType.attempted": true,
      "EndgameType.spotlight": true
    }
  ]
  ''';
  parseAndLogJson(jsonString);
}