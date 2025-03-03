import 'dart:convert';

import 'package:hive/hive.dart';

class Settings {
  static void setApiKey(String key) {
    LocalDataBase.putData('Settings.apiKey', key);
  }

  static String getApiKey() {
    return LocalDataBase.getData('Settings.apiKey');
  }
}

// PitDataBase
class PitDataBase {
  static final Map<String, dynamic> _storage = {};

  static void PutData(dynamic key, PitRecord value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    // print(' Storing $key as $value');
    _storage[key.toString()] = value.toJson();
  }

  static dynamic GetData(dynamic key) {
    // print('Retrieving $key as ${_storage[key.toString()]}');
    return jsonDecode(jsonEncode(_storage[key.toString()]));
  }

  static void DeleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void ClearData() {
    // print('Clearing all data');
    Hive.box('pitData').put('data', null);
    _storage.clear();
  }

  static void SaveAll() {
    Hive.box('pitData').put('data', jsonEncode(_storage));
  }

  static void LoadAll() {
    var dd = Hive.box('pitData').get('data');
    if (dd != null) {
      _storage.addAll(json.decode(dd));
    }
  }

  static void PrintAll() {
    print(_storage);
  }

  static List<int> GetRecorderTeam() {
    List<int> teams = [];
    _storage.forEach((key, value) {
      teams.add(value['teamNumber']);
    });
    return teams;
  }

  static dynamic Export() {
    return _storage;
  }
}

class PitRecord {
  final int teamNumber;
  final String scouterName;
  final String eventKey;
  final String keyStrengths;
  final String keyWeaknesses;
  final String defensiveStratigiy;
  final String defensePlan;

  PitRecord(
      {required this.teamNumber,
      required this.scouterName,
      required this.eventKey,
      required this.keyStrengths,
      required this.keyWeaknesses,
      required this.defensiveStratigiy,
      required this.defensePlan});

  Map<String, dynamic> toJson() {
    return {
      "teamNumber": teamNumber,
      "scouterName": scouterName,
      "eventKey": eventKey,
      "keyStrengths": keyStrengths,
      "keyWeaknesses": keyWeaknesses,
      "defensiveStratigiy": defensiveStratigiy,
      "defensePlan": defensePlan
    };
  }
}

// QualitativeDataBase
class QualitativeDataBase {
  static final Map<String, dynamic> _storage = {};

  static void PutData(dynamic key, dynamic value) {
    if (key == null) {
      throw Exception('Both keys cannot be null');
    }

    if (!_storage.containsKey(key.toString())) {
      _storage[key.toString()] = {};
    }

    _storage[key.toString()] = value;
  }

  static dynamic GetData(dynamic key) {
    return _storage[key.toString()];
  }

  static void DeleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void ClearData() {
    // print('Clearing all data');
    Hive.box('qualitative').put('data', null);
    _storage.clear();
  }

  static void SaveAll() {
    Hive.box('qualitative').put('data', jsonEncode(_storage));
  }

  static void LoadAll() {
    var dd = Hive.box('qualitative').get('data');
    if (dd != null) {
      _storage.addAll(json.decode(dd));
    }
  }

  static void PrintAll() {
    print(_storage);
  }

  static List<String> GetRecorderTeam() {
    List<String> teams = [];
    _storage.forEach((key, value) {
      teams.add(value['teamNumber']);
    });
    return teams;
  }

  static dynamic Export() {
    return _storage;
  }
}

class QualitativeRecord {
  String scouterName;
  String matchKey;
  int matchNumber;
  String alliance;
  String q1;
  String q2;
  String q3;
  String q4;

  QualitativeRecord(
      {required this.scouterName,
      required this.matchKey,
      required this.matchNumber,
      required this.alliance,
      required this.q1,
      required this.q2,
      required this.q3,
      required this.q4});

  Map<String, dynamic> toJson() {
    return {
      "Scouter_Name": scouterName,
      "Match_Key": matchKey,
      "Match_Number": matchNumber,
      "Alliance": alliance,
      "Q1": q1,
      "Q2": q2,
      "Q3": q3,
      "Q4": q4,
    };
  }

  static QualitativeRecord fromJson(Map<String, dynamic> json) {
    return QualitativeRecord(
      scouterName: json['Scouter_Name'] ?? "",
      matchKey: json['Match_Key'] ?? "",
      matchNumber: json['Match_Number'] ?? 0,
      alliance: json['Alliance'] ?? "",
      q1: json['Q1'] ?? "",
      q2: json['Q2'] ?? "",
      q3: json['Q3'] ?? "",
      q4: json['Q4'] ?? "",
    );
  }

  @override
  String toString() {
    return 'QualitativeRecord{scouterName: $scouterName, matchKey: $matchKey, matchNumber: $matchNumber, alliance: $alliance, q1: $q1, q2: $q2, q3: $q3, q4: $q4}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QualitativeRecord &&
        other.scouterName == scouterName &&
        other.matchKey == matchKey &&
        other.matchNumber == matchNumber &&
        other.alliance == alliance &&
        other.q1 == q1 &&
        other.q2 == q2 &&
        other.q3 == q3 &&
        other.q4 == q4;
  }

  @override
  int get hashCode {
    return scouterName.hashCode ^
        matchKey.hashCode ^
        matchNumber.hashCode ^
        alliance.hashCode ^
        q1.hashCode ^
        q2.hashCode ^
        q3.hashCode ^
        q4.hashCode;
  }

  static QualitativeRecord fromMap(Map<String, dynamic> map) {
    return QualitativeRecord(
      scouterName: map['Scouter_Name'] ?? "",
      matchKey: map['Match_Key'] ?? "",
      matchNumber: map['Match_Number'] ?? 0,
      alliance: map['Alliance'] ?? "",
      q1: map['Q1'] ?? "",
      q2: map['Q2'] ?? "",
      q3: map['Q3'] ?? "",
      q4: map['Q4'] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Scouter_Name': scouterName,
      'Match_Key': matchKey,
      'Match_Number': matchNumber,
      'Alliance': alliance,
      'Q1': q1,
      'Q2': q2,
      'Q3': q3,
      'Q4': q4,
    };
  }

  SetQ1(String value) {
    q1 = value;
  }

  SetQ2(String value) {
    q2 = value;
  }

  SetQ3(String value) {
    q3 = value;
  }

  SetQ4(String value) {
    q4 = value;
  }

  SetScouterName(String value) {
    scouterName = value;
  }

  SetMatchKey(String value) {
    matchKey = value;
  }

  SetMatchNumber(int value) {
    matchNumber = value;
  }

  SetAlliance(String value) {
    alliance = value;
  }

  getQ1() {
    return q1;
  }

  getQ2() {
    return q2;
  }

  getQ3() {
    return q3;
  }

  getQ4() {
    return q4;
  }

  getScouterName() {
    return scouterName;
  }

  getMatchKey() {
    return matchKey;
  }

  getMatchNumber() {
    return matchNumber;
  }

  getAlliance() {
    return alliance;
  }

  getAll() {
    return {
      'Scouter_Name': scouterName,
      'Match_Key': matchKey,
      'Match_Number': matchNumber,
      'Alliance': alliance,
      'Q1': q1,
      'Q2': q2,
      'Q3': q3,
      'Q4': q4,
    };
  }
}

// MatchDataBase
class MatchDataBase {
  static final Map<String, dynamic> _storage = {};

  static void PutData(dynamic key, MatchRecord value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    // print(' Storing $key as $value');
    _storage[key.toString()] = value.toJson();
  }

  static dynamic GetData(dynamic key) {
    // print('Retrieving $key as ${_storage[key.toString()]}');
    return jsonDecode(jsonEncode(_storage[key.toString()]));
  }

  static void DeleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void ClearData() {
    // print('Clearing all data');
    Hive.box('match').put('data', null);
    _storage.clear();
  }

  static void SaveAll() {
    Hive.box('match').put('data', jsonEncode(_storage));
  }

  static void LoadAll() {
    var dd = Hive.box('match').get('data');
    if (dd != null) {
      _storage.addAll(json.decode(dd));
    }
  }

  static void PrintAll() {
    print(_storage);
  }

  static List<int> GetRecorderTeam() {
    List<int> teams = [];
    _storage.forEach((key, value) {
      teams.add(value['teamNumber']);
    });
    return teams;
  }

  static dynamic Export() {
    return _storage;
  }

  static List<MatchRecord> GetAll() {
    List<MatchRecord> records = [];
    _storage.forEach((key, value) {
      records.add(MatchRecord.fromJson(value));
    });
    return records;
  }

  static MatchRecord fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      AutonPoints.fromJson(json['autonPoints'] ?? {}),
      TeleOpPoints.fromJson(json['teleOpPoints'] ?? {}),
      EndPoints.fromJson(json['endPoints'] ?? {}),
      teamNumber: json['teamNumber'] ?? "",
      scouterName: json['scouterName'] ?? "",
      matchKey: json['matchKey'] ?? "",
      allianceColor: json['allianceColor'] ?? "",
      eventKey: json['eventKey'] ?? "",
      station: json['station'] ?? 0,
      matchNumber: json['matchNumber'] ?? 0,
    );
  }

  static MatchRecord fromMap(Map<String, dynamic> map) {
    return MatchRecord(
      AutonPoints.fromJson(map['autonPoints'] ?? {}),
      TeleOpPoints.fromJson(map['teleOpPoints'] ?? {}),
      EndPoints.fromJson(map['endPoints'] ?? {}),
      teamNumber: map['teamNumber'] ?? "",
      scouterName: map['scouterName'] ?? "",
      matchKey: map['matchKey'] ?? "",
      allianceColor: map['allianceColor'] ?? "",
      eventKey: map['eventKey'] ?? "",
      station: map['station'] ?? 0,
      matchNumber: map['matchNumber'] ?? 0,
    );
  }

  static Map<String, dynamic> toMap(MatchRecord record) {
    return {
      'teamNumber': record.teamNumber,
      'scouterName': record.scouterName,
      'matchKey': record.matchKey,
      'allianceColor': record.allianceColor,
      'eventKey': record.eventKey,
      'station': record.station,
      'matchNumber': record.matchNumber,
      'autonPoints': record.autonPoints.toJson(),
      'teleOpPoints': record.teleOpPoints.toJson(),
      'endPoints': record.endPoints.toJson(),
    };
  }

  static List<MatchRecord> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => fromJson(json)).toList();
  }

  static List<Map<String, dynamic>> toJsonList(List<MatchRecord> records) {
    return records.map((record) => record.toJson()).toList();
  }

  static List<MatchRecord> fromMapList(List<Map<String, dynamic>> mapList) {
    return mapList.map((map) => fromMap(map)).toList();
  }

  static List<Map<String, dynamic>> toMapList(List<MatchRecord> records) {
    return records.map((record) => toMap(record)).toList();
  }
}

class MatchRecord {
  final String teamNumber;
  final String scouterName;
  final String matchKey;
  final int matchNumber;
  final String allianceColor;
  final String eventKey;
  final int station;
  AutonPoints autonPoints;
  TeleOpPoints teleOpPoints;
  EndPoints endPoints;

  MatchRecord(
    this.autonPoints,
    this.teleOpPoints,
    this.endPoints, {
    required this.teamNumber,
    required this.scouterName,
    required this.matchKey,
    required this.allianceColor,
    required this.eventKey,
    required this.station,
    required this.matchNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      "teamNumber": teamNumber,
      "scouterName": scouterName,
      "matchKey": matchKey,
      "allianceColor": allianceColor,
      "eventKey": eventKey,
      "station": station,
      "autonPoints": autonPoints.toJson(),
      "teleOpPoints": teleOpPoints.toJson(),
      "endPoints": endPoints.toJson(),
    };
  }

  static MatchRecord fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      AutonPoints.fromJson(json['autonPoints'] ?? {}),
      TeleOpPoints.fromJson(json['teleOpPoints'] ?? {}),
      EndPoints.fromJson(json['endPoints'] ?? {}),
      teamNumber: json['teamNumber'] ?? "",
      scouterName: json['scouterName'] ?? "",
      matchKey: json['matchKey'] ?? "",
      allianceColor: json['allianceColor'] ?? "",
      eventKey: json['eventKey'] ?? "",
      station: json['station'] ?? 0,
      matchNumber: json['matchNumber'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'MatchRecord{teamNumber: $teamNumber, scouterName: $scouterName, matchKey: $matchKey, autonPoints: $autonPoints, teleOpPoints: $teleOpPoints, endPoints: $endPoints, allianceColor: $allianceColor, eventKey: $eventKey, station: $station}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchRecord &&
        other.teamNumber == teamNumber &&
        other.scouterName == scouterName &&
        other.matchKey == matchKey &&
        other.autonPoints == autonPoints &&
        other.teleOpPoints == teleOpPoints &&
        other.endPoints == endPoints;
  }

  @override
  int get hashCode {
    return teamNumber.hashCode ^
        scouterName.hashCode ^
        matchKey.hashCode ^
        autonPoints.hashCode ^
        teleOpPoints.hashCode ^
        endPoints.hashCode;
  }
}

// AutonPoints
class AutonPoints {
  int CoralScoringLevel1 = 0;
  int CoralScoringLevel2 = 0;
  int CoralScoringLevel3 = 0;
  int CoralScoringLevel4 = 0;
  bool LeftBarge = false;
  int AlgaeScoringProcessor = 0;
  int AlgaeScoringBarge = 0;

  AutonPoints(
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.LeftBarge,
    this.AlgaeScoringProcessor,
    this.AlgaeScoringBarge,
  );

  Map<String, dynamic> toJson() {
    return {
      "CoralScoringLevel1": CoralScoringLevel1,
      "CoralScoringLevel2": CoralScoringLevel2,
      "CoralScoringLevel3": CoralScoringLevel3,
      "CoralScoringLevel4": CoralScoringLevel4,
      "LeftBarge": LeftBarge,
      "AlgaeScoringProcessor": AlgaeScoringProcessor,
      "AlgaeScoringBarge": AlgaeScoringBarge,
    };
  }

  static AutonPoints fromJson(Map<String, dynamic> json) {
    return AutonPoints(
      json['CoralScoringLevel1'] ?? 0,
      json['CoralScoringLevel2'] ?? 0,
      json['CoralScoringLevel3'] ?? 0,
      json['CoralScoringLevel4'] ?? 0,
      json['LeftBarge'] ?? false,
      json['AlgaeScoringProcessor'] ?? 0,
      json['AlgaeScoringBarge'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'AutonPoints{CoralScoringLevel1: $CoralScoringLevel1, CoralScoringLevel2: $CoralScoringLevel2, CoralScoringLevel3: $CoralScoringLevel3, CoralScoringLevel4: $CoralScoringLevel4, LeftBarge: $LeftBarge, AlgaeScoringProcessor: $AlgaeScoringProcessor, AlgaeScoringBarge: $AlgaeScoringBarge}';
  }

  setCoralScoringL1(int value) {
    CoralScoringLevel1 = value;
  }

  setCoralScoringL2(int value) {
    CoralScoringLevel2 = value;
  }

  setCoralScoringL3(int value) {
    CoralScoringLevel3 = value;
  }

  setCoralScoringL4(int value) {
    CoralScoringLevel4 = value;
  }

  setAlgaeScoringProcessor(int value) {
    AlgaeScoringProcessor = value;
  }

  setAlgaeScoringBarge(int value) {
    AlgaeScoringBarge = value;
  }

  setLeftBarge(bool value) {
    LeftBarge = value;
  }
}

// TeleOpPoints
class TeleOpPoints {
  int CoralScoringLevel1 = 0;
  int CoralScoringLevel2 = 0;
  int CoralScoringLevel3 = 0;
  int CoralScoringLevel4 = 0;
  int AlgaeScoringBarge = 0;
  int AlgaeScoringProcessor = 0;
  bool Defense = true;

  TeleOpPoints(
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.AlgaeScoringBarge,
    this.AlgaeScoringProcessor,
    this.Defense,
  );

  Map<String, dynamic> toJson() {
    return {
      "CoralScoringLevel1": CoralScoringLevel1,
      "CoralScoringLevel2": CoralScoringLevel2,
      "CoralScoringLevel3": CoralScoringLevel3,
      "CoralScoringLevel4": CoralScoringLevel4,
      "AlgaeScoringBarge": AlgaeScoringBarge,
      "AlgaeScoringProcessor": AlgaeScoringProcessor,
      "Defense": Defense,
    };
  }

  static TeleOpPoints fromJson(Map<String, dynamic> json) {
    return TeleOpPoints(
      json['CoralScoringLevel1'] ?? 0,
      json['CoralScoringLevel2'] ?? 0,
      json['CoralScoringLevel3'] ?? 0,
      json['CoralScoringLevel4'] ?? 0,
      json['AlgaeScoringBarge'] ?? 0,
      json['AlgaeScoringProcessor'] ?? 0,
      json['Defense'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'TeleOpPoints{CoralScoringLevel1: $CoralScoringLevel1, CoralScoringLevel2: $CoralScoringLevel2, CoralScoringLevel3: $CoralScoringLevel3, CoralScoringLevel4: $CoralScoringLevel4, AlgaeScoringBarge: $AlgaeScoringBarge, AlgaeScoringProcessor: $AlgaeScoringProcessor, Defense: $Defense}';
  }

  setCoralScoringL1(int value) {
    CoralScoringLevel1 = value;
  }

  setCoralScoringL2(int value) {
    CoralScoringLevel2 = value;
  }

  setCoralScoringL3(int value) {
    CoralScoringLevel3 = value;
  }

  setCoralScoringL4(int value) {
    CoralScoringLevel4 = value;
  }

  setAlgaeScoringProcessor(int value) {
    AlgaeScoringProcessor = value;
  }

  setAlgaeScoringBarge(int value) {
    AlgaeScoringBarge = value;
  }

  setDefense(bool value) {
    Defense = value;
  }
}

// EndPoints
class EndPoints {
  bool Deep_Climb = false;
  bool Shallow_Climb = false;
  bool Park = false;
  String Comments = '';

  EndPoints(
    this.Deep_Climb,
    this.Shallow_Climb,
    this.Park,
    this.Comments,
  );

  Map<String, dynamic> toJson() {
    return {
      "Deep_Climb": Deep_Climb,
      "Shallow_Climb": Shallow_Climb,
      "Park": Park,
      "Comments": Comments,
    };
  }

  static EndPoints fromJson(Map<String, dynamic> json) {
    return EndPoints(
      json['Deep_Climb'] ?? 0,
      json['Shallow_Climb'] ?? 0,
      json['Park'] ?? 0,
      json['Comments'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'EndPoints{Deep_Climb: $Deep_Climb, Shallow_Climb: $Shallow_Climb, Park: $Park, Comments: $Comments}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EndPoints &&
        other.Deep_Climb == Deep_Climb &&
        other.Shallow_Climb == Shallow_Climb &&
        other.Park == Park &&
        other.Comments == Comments;
  }

  @override
  int get hashCode {
    return Deep_Climb.hashCode ^
        Shallow_Climb.hashCode ^
        Park.hashCode ^
        Comments.hashCode;
  }

  setDeepClimb(bool value) {
    Deep_Climb = value;
  }

  setShallowClimb(bool value) {
    Shallow_Climb = value;
  }

  setPark(bool value) {
    Park = value;
  }
}

// Utils
class Team {
  final int teamNumber;
  final String nickname;
  final String? city;
  final String? stateProv;
  final String? country;
  final String? website;

  Team({
    required this.teamNumber,
    required this.nickname,
    this.city,
    this.stateProv,
    this.country,
    this.website,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      teamNumber: json['team_number'],
      nickname: json['nickname'],
      city: json['city'],
      stateProv: json['state_prov'],
      country: json['country'],
      website: json['website'],
    );
  }
}

class LocalDataBase {
  static void putData(String key, dynamic value) {
    Hive.box('local').put(key, value);
  }

  // Get data from local storage
  static dynamic getData(String key) {
    return Hive.box('local').get(key);
  }

  // Helper conversion methods
  static AutonPoints mapToAutonPoints(Map<dynamic, dynamic> data) {
    return AutonPoints(
      data['CoralScoringLevel1'] ?? 0,
      data['CoralScoringLevel2'] ?? 0,
      data['CoralScoringLevel3'] ?? 0,
      data['CoralScoringLevel4'] ?? 0,
      data['LeftBarge'] ?? false,
      data['AlgaeScoringProcessor'] ?? 0,
      data['AlgaeScoringBarge'] ?? 0,
    );
  }

  static TeleOpPoints mapToTeleOpPoints(Map<dynamic, dynamic> data) {
    return TeleOpPoints(
      data['CoralScoringLevel1'] ?? 0,
      data['CoralScoringLevel2'] ?? 0,
      data['CoralScoringLevel3'] ?? 0,
      data['CoralScoringLevel4'] ?? 0,
      data['AlgaeScoringProcessor'] ?? 0,
      data['AlgaeScoringBarge'] ?? 0,
      data['Defended'] ?? false,
    );
  }

  static EndPoints mapToEndPoints(Map<dynamic, dynamic> data) {
    return EndPoints(
      data['TrapScored'] ?? 0,
      data['SpotlightLevel'] ?? 0,
      data['Harmonize'] ?? false,
      data['Park'] ?? false,
    );
  }
}
