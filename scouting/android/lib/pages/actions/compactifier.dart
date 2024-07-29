import 'dart:convert';

String convertToCompactFormat(Map<String, dynamic> dataMap) {
  // Compact data representation with null checks
  return "ek:${dataMap['Types.eventKey'] ?? ''},ac:${dataMap['Types.allianceColor']?[0] ?? ''},"
      "ss:${dataMap['Types.selectedStation'] ?? ''},mk:${dataMap['Types.matchKey'] ?? ''},t:${dataMap['Types.team'] ?? ''},"
      "asp:${dataMap['AutoType.StartPosition']?['dx'] ?? ''},${dataMap['AutoType.StartPosition']?['dy'] ?? ''},"
      "ap:${dataMap['AutoType.AmpPlacement'] ?? ''},s:${dataMap['AutoType.Speaker'] ?? ''},t:${dataMap['AutoType.Trap'] ?? ''},"
      "ar:${dataMap['AutoType.AutonRating'] ?? ''},c1:${dataMap['AutoType.Chip1'] == true ? 1 : 0},"
      "c2:${dataMap['AutoType.Chip2'] == true ? 1 : 0},c3:${dataMap['AutoType.Chip3'] == true ? 1 : 0},"
      "gpu:${dataMap['TeleType.GroundPickUp'] ?? ''},spu:${dataMap['TeleType.SourcePickUp'] ?? ''},"
      "sn:${dataMap['TeleType.SpeakerNotes'] ?? ''},ap:${dataMap['TeleType.AmpPlacement'] ?? ''},"
      "tp:${dataMap['TeleType.TrapPlacement'] ?? ''},asn:${dataMap['TeleType.AmplifiedSpeakerNotes'] ?? ''},"
      "cb:${dataMap['TeleType.CoOpBonus'] == true ? 1 : 0},a:${dataMap['TeleType.Assists'] ?? ''},"
      "el:${dataMap['EndgameType.endLocation']?['dx'] ?? ''},${dataMap['EndgameType.endLocation']?['dy'] ?? ''},"
      "cl:${dataMap['EndgameType.climbed'] == true ? 1 : 0},tn:${dataMap['EndgameType.trapNotePosition'] ?? ''},"
      "h:${dataMap['EndgameType.harmony'] == true ? 1 : 0},cm:'${dataMap['EndgameType.comments'] ?? ''}'";
}

String convertToJsonFormat(Map<String, dynamic> dataMap) {
  try {
    return jsonEncode(dataMap);
  } catch (e) {
    print('Error in convertToJsonFormat: $e');
    return '';
  }
}
