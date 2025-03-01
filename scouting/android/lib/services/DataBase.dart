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
  final String scouterName;
  final String matchKey;
  final String q1;
  final String q2;
  final String q3;
  final String q4;

  QualitativeRecord(
      {required this.scouterName,
      required this.matchKey,
      required this.q1,
      required this.q2,
      required this.q3,
      required this.q4});

  Map<String, dynamic> toJson() {
    return {
      "Scouter_Name": scouterName,
      "Match_Key": matchKey,
      "Q1": q1,
      "Q2": q2,
      "Q3": q3,
      "Q4": q4,
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
}

class MatchRecord {
  final String teamNumber;
  final String scouterName;
  final String matchKey;
  final String allianceColor;
  final String eventKey;
  final String station;
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
      teamNumber: json['teamNumber'] ?? 0,
      scouterName: json['scouterName'] ?? "",
      matchKey: json['matchKey'] ?? "",
      allianceColor: json['allianceColor'] ?? "",
      eventKey: json['eventKey'] ?? "",
      station: json['station'] ?? "",
    );
  }

  @override
  String toString() {
    return 'MatchRecord{teamNumber: $teamNumber, scouterName: $scouterName, matchKey: $matchKey, autonPoints: $autonPoints, teleOpPoints: $teleOpPoints, endPoints: $endPoints}';
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
  bool Defense = false;

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
  int Deep_Climb = 0;
  int Shallow_Climb = 0;
  int Park = 0;
  int Comments = 0;

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

  setDeepClimb(int value) {
    Deep_Climb = value;
  }

  setShallowClimb(int value) {
    Shallow_Climb = value;
  }

  setPark(int value) {
    Park = value;
  }

  setComments(int value) {
    Comments = value;
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

  static dynamic getData(String key) {
    return Hive.box('local').get(key);
  }

  static void deleteData(String key) {
    Hive.box('local').delete(key);
  }

  static void clearData() {
    Hive.box('local').clear();
  }

  static void printAll() {
    print(Hive.box('local').toMap());
  }
}
