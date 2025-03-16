import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';

class Settings {
  static void setApiKey(String key) {
    LocalDataBase.putData('Settings.apiKey', key);
  }

  static void setPitKey(String key) {
    LocalDataBase.putData('Settings.pitKey', key);
  }

  static String getApiKey() {
    return LocalDataBase.getData('Settings.apiKey');
  }

  static String getPitKey() {
    return LocalDataBase.getData('Settings.pitKey');
  }
}

// PitDataBase
class PitDataBase {
  static final Map<String, PitRecord> _storage = {};

  static void PutData(dynamic key, PitRecord value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    // print(' Storing $key as $value');
    _storage[key.toString()] = value;
  }

  static PitRecord? GetData(dynamic key) {
    // print('Retrieving $key as ${_storage[key]}');
    if (_storage[key.toString()] == null) {
      return null;
    }

    // Convert the stored data to a PitRecord object
    var data = _storage[key.toString()];
    if (data is PitRecord) {
      return data;
    } else if (data is Map<String, dynamic>) {
      // ignore: cast_from_null_always_fails
      return PitRecord.fromJson(data as Map<String, dynamic>);
    }

    return null;
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
      Map<String, dynamic> data = json.decode(dd);
      data.forEach((key, value) {
        _storage[key] = value is Map
            ? PitRecord.fromJson(value as Map<String, dynamic>)
            : value;
      });
    }
  }

  static void PrintAll() {
    print(_storage);
  }

  static List<int> GetRecorderTeam() {
    List<int> teams = [];
    _storage.forEach((key, value) {
      teams.add(value.teamNumber);
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
  final String driveTrainType;
  final String autonType;
  final List<String> scoreObject;
  final List<String> scoreType;
  final String intake;
  final List<String> climbType;
  final String imageblob;

  PitRecord({
    required this.teamNumber,
    required this.scouterName,
    required this.eventKey,
    required this.driveTrainType,
    required this.autonType,
    required this.scoreObject,
    required this.scoreType,
    required this.intake,
    required this.climbType,
    required this.imageblob,
  });

  Map<String, dynamic> toJson() {
    return {
      "teamNumber": teamNumber,
      "scouterName": scouterName,
      "eventKey": eventKey,
      "driveTrain": driveTrainType,
      "auton": autonType,
      "scoreObject": scoreObject.toString(),
      "scoreType": scoreType,
      "intake": intake,
      "climbType": climbType,
      "imageblob": imageblob
    };
  }

  factory PitRecord.fromJson(Map<String, dynamic> json) {
    // Parse scoreObject which might be a string representation of a list
    List<String> parseScoreObject() {
      var scoreObj = json['scoreObject'];
      if (scoreObj == null) return [];
      if (scoreObj is List) return List<String>.from(scoreObj);
      if (scoreObj is String) {
        // Parse string representation of list
        if (scoreObj.startsWith('[') && scoreObj.endsWith(']')) {
          String listContent = scoreObj.substring(1, scoreObj.length - 1);
          return listContent.isEmpty
              ? []
              : listContent.split(', ').map((s) => s.trim()).toList();
        }
      }
      return [];
    }

    return PitRecord(
      teamNumber: json['teamNumber'] ?? 0,
      scouterName: json['scouterName'] ?? '',
      eventKey: json['eventKey'] ?? '',
      // These field names didn't match what's in toJson
      driveTrainType: json['driveTrain'] ?? '',
      autonType: json['auton'] ?? '',
      scoreType:
          json['scoreType'] is List ? List<String>.from(json['scoreType']) : [],
      scoreObject: parseScoreObject(),
      intake: json['intake'] ?? '',
      climbType:
          json['climbType'] is List ? List<String>.from(json['climbType']) : [],

      imageblob: json['imageblob'] ?? '',
    );
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
  String scouterName;
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
      "matchNumber": matchNumber,
      "allianceColor": allianceColor,
      "eventKey": eventKey,
      "station": station,
      "autonPoints": autonPoints.toJson(),
      "teleOpPoints": teleOpPoints.toJson(),
      "endPoints": endPoints.toJson(),
    };
  }

  String toCsv() {
    return '${teamNumber},${scouterName},${matchKey},${allianceColor},${eventKey},${station},${matchNumber}, ${autonPoints.toCsv()}, ${teleOpPoints.toCsv()}, ${endPoints.toCsv()}';
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

  String toJsonString() {
    return jsonEncode(this.toJson());
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
  BotLocation robot_position;

  AutonPoints(
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.LeftBarge,
    this.AlgaeScoringProcessor,
    this.AlgaeScoringBarge,
    this.robot_position,
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
      "RobotLocation": robot_position.toJson(),
    };
  }

  String toCsv() {
    return '${CoralScoringLevel1},${CoralScoringLevel2},${CoralScoringLevel3},${CoralScoringLevel4},${LeftBarge},${AlgaeScoringProcessor},${AlgaeScoringBarge},${robot_position.toCsv()}';
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
      BotLocation.fromJson(json['RobotLocation'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'AutonPoints{CoralScoringLevel1: $CoralScoringLevel1, CoralScoringLevel2: $CoralScoringLevel2, CoralScoringLevel3: $CoralScoringLevel3, CoralScoringLevel4: $CoralScoringLevel4, LeftBarge: $LeftBarge, AlgaeScoringProcessor: $AlgaeScoringProcessor, AlgaeScoringBarge: $AlgaeScoringBarge, RobotLocation: $robot_position}';
  }

  void setCoralScoringL1(int value) {
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
  int AlgaePickUp = 0;
  bool Defense = true;

  TeleOpPoints(
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.AlgaeScoringBarge,
    this.AlgaeScoringProcessor,
    this.AlgaePickUp,
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
      "AlgaePickUp": AlgaePickUp,
      "Defense": Defense,
    };
  }

  String toCsv() {
    return '${CoralScoringLevel1},${CoralScoringLevel2},${CoralScoringLevel3},${CoralScoringLevel4},${AlgaeScoringBarge},${AlgaeScoringProcessor},${AlgaePickUp},${Defense}';
  }

  static TeleOpPoints fromJson(Map<String, dynamic> json) {
    return TeleOpPoints(
      json['CoralScoringLevel1'] ?? 0,
      json['CoralScoringLevel2'] ?? 0,
      json['CoralScoringLevel3'] ?? 0,
      json['CoralScoringLevel4'] ?? 0,
      json['AlgaeScoringBarge'] ?? 0,
      json['AlgaeScoringProcessor'] ?? 0,
      json['AlgaePickUp'] ?? 0,
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

  String toCsv() {
    return '$Deep_Climb,$Shallow_Climb,$Park,$Comments';
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
        data['RobotLocation'] ?? Offset.zero);
  }

  static TeleOpPoints mapToTeleOpPoints(Map<dynamic, dynamic> data) {
    return TeleOpPoints(
      data['CoralScoringLevel1'] ?? 0,
      data['CoralScoringLevel2'] ?? 0,
      data['CoralScoringLevel3'] ?? 0,
      data['CoralScoringLevel4'] ?? 0,
      data['AlgaeScoringProcessor'] ?? 0,
      data['AlgaeScoringBarge'] ?? 0,
      data['AlgaePickUp'] ?? 0,
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

  static PitRecord mapToPitRecord(Map<dynamic, dynamic> data) {
    return PitRecord(
      teamNumber: data['teamNumber'] ?? 0,
      eventKey: data['eventKey'] ?? "",
      scouterName: data['scouterName'] ?? "",
      driveTrainType: data['driveTrainType'] ?? "",
      autonType: data['auton'] ?? "",
      intake: data['intake'] ?? "",
      scoreObject: List<String>.from(data['scoreObject'] ?? []),
      climbType: List<String>.from(data['climbType'] ?? []),
      scoreType: List<String>.from(data['scoreType'] ?? []),
      imageblob: data['imageblob'] ?? "",
    );
  }
}

class BotLocation {
  Offset position;
  Size size;
  double angle;

  BotLocation(this.position, this.size, this.angle);

  Map<String, dynamic> toJson() {
    return {
      'position': {'x': position.dx, 'y': position.dy},
      'size': {'width': size.width, 'height': size.height},
      'angle': angle,
    };
  }

  static BotLocation fromJson(Map<String, dynamic> json) {
    return BotLocation(
      Offset(json['position']['x'], json['position']['y']),
      Size(json['size']['width'], json['size']['height']),
      json['angle'],
    );
  }

  String toCsv() {
    return '${position.dx},${position.dy},${size.width},${size.height},$angle';
  }
}
