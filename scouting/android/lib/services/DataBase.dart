import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toInt();
  return 0;
}

class Settings {
  static void setApiKey(String key) {
    LocalDataBase.putData('Settings.apiKey', key);
  }

  static void setPitKey(String key) {
    LocalDataBase.putData('Settings.pitKey', key);
  }

  static String getApiKey() {
    return LocalDataBase.getData('Settings.apiKey') ?? '';
  }

  static String getPitKey() {
    return LocalDataBase.getData('Settings.pitKey') ?? '';
  }

  static void setNeonHost(String host) {
    LocalDataBase.putData('Settings.neonHost', host);
  }

  static String getNeonHost() {
    return LocalDataBase.getData('Settings.neonHost') ?? '';
  }

  static void setNeonUser(String user) {
    LocalDataBase.putData('Settings.neonUser', user);
  }

  static String getNeonUser() {
    return LocalDataBase.getData('Settings.neonUser') ?? '';
  }

  static void setNeonPassword(String password) {
    LocalDataBase.putData('Settings.neonPassword', password);
  }

  static String getNeonPassword() {
    return LocalDataBase.getData('Settings.neonPassword') ?? '';
  }

  static void setNeonDatabase(String db) {
    LocalDataBase.putData('Settings.neonDatabase', db);
  }

  static String getNeonDatabase() {
    return LocalDataBase.getData('Settings.neonDatabase') ?? '';
  }

  static void setNeonRestUrl(String url) {
    LocalDataBase.putData('Settings.neonRestUrl', url);
  }

  static String getNeonRestUrl() {
    return LocalDataBase.getData('Settings.neonRestUrl') ?? '';
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
  final List<String> climbType;
  final String botImage1;
  final String botImage2;
  final String botImage3;

  // New FRC 2026 Fields
  final String autoRoutes;
  final int autoFuel;
  final bool gameData;
  final double weight;
  final double speed;
  final String driveMotorType;
  final double groundClearance;
  final int maxFuelCapacity;
  final double avgCycleTime;
  final double climbSuccessProb;
  final int batteries;
  final String framePerimeter;
  final double shootingRate;
  final bool hopperSealed;
  final String trenchUnder;
  final bool bumpOver;
  final int driverYear;
  final String interviewerName;
  final String interviewerRole;
  final bool attitude;
  final String scoutingAccuracy;
  final String notCooperativeReason;
  final List<Map<String, String?>> pathDraw;

  PitRecord(
      {required this.teamNumber,
      required this.scouterName,
      required this.eventKey,
      required this.driveTrainType,
      required this.autonType,
      required this.scoreObject,
      required this.scoreType,
      required this.climbType,
      required this.botImage1,
      required this.botImage2,
      required this.botImage3,
      this.autoRoutes =  '',
      this.autoFuel = 0,
      this.gameData = false,
      this.weight = 0.0,
      this.speed = 0.0,
      this.driveMotorType = '',
      this.groundClearance = 0.0,
      this.maxFuelCapacity = 0,
      this.avgCycleTime = 0.0,
      this.climbSuccessProb = 0.0,
      this.batteries = 0,
      this.framePerimeter = '',
      this.shootingRate = 0.0,
      this.hopperSealed = false,
      this.trenchUnder = '',
      this.bumpOver = false,
      this.driverYear = 0,
      this.interviewerName = '',
      this.interviewerRole = '',
      this.attitude = true,
      this.scoutingAccuracy = '',
      this.notCooperativeReason = '',
      this.pathDraw = const []});

  Map<String, dynamic> toJson() {
    return {
      "teamNumber": teamNumber,
      "scouterName": scouterName,
      "eventKey": eventKey,
      "driveTrain": driveTrainType,
      "auton": autonType,
      "scoreObject": scoreObject.toString(),
      "scoreType": scoreType,
      "climbType": climbType,
      "botImage1": botImage1,
      "botImage2": botImage2,
      "botImage3": botImage3,
      "autoRoutes": autoRoutes,
      "autoFuel": autoFuel,
      "gameData": gameData,
      "weight": weight,
      "speed": speed,
      "driveMotorType": driveMotorType,
      "groundClearance": groundClearance,
      "maxFuelCapacity": maxFuelCapacity,
      "avgCycleTime": avgCycleTime,
      "climbSuccessProb": climbSuccessProb,
      "batteries": batteries,
      "framePerimeter": framePerimeter,
      "shootingRate": shootingRate,
      "hopperSealed": hopperSealed,
      "trenchUnder": trenchUnder,
      "bumpOver": bumpOver,
      "driverYear": driverYear,
      "interviewerName": interviewerName,
      "interviewerRole": interviewerRole,
      "attitude": attitude,
      "scoutingAccuracy": scoutingAccuracy,
      "notCooperativeReason": notCooperativeReason,
      "pathDraw": pathDraw
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

    // Parse intake which might also be a string representation of a list
    List<String> parseIntake() {
      var intakeData = json['intake'];
      if (intakeData == null) return [];
      if (intakeData is List) return List<String>.from(intakeData);
      if (intakeData is String) {
        // Parse string representation of list
        if (intakeData.startsWith('[') && intakeData.endsWith(']')) {
          String listContent = intakeData.substring(1, intakeData.length - 1);
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
      scoreObject: List<String>.from(parseScoreObject()),
      climbType:
          json['climbType'] is List ? List<String>.from(json['climbType']) : [],

      botImage1: json['botImage1'] ?? '',
      botImage2: json['botImage2'] ?? '',
      botImage3: json['botImage3'] ?? '',

      autoRoutes: json['autoRoutes'] ?? '',
      autoFuel: json['autoFuel'] ?? 0,
      gameData: json['gameData'] ?? false,
      weight: (json['weight'] ?? 0.0).toDouble(),
      speed: (json['speed'] ?? 0.0).toDouble(),
      driveMotorType: json['driveMotorType'] ?? '',
      groundClearance: (json['groundClearance'] ?? 0.0).toDouble(),
      maxFuelCapacity: json['maxFuelCapacity'] ?? 0,
      avgCycleTime: (json['avgCycleTime'] ?? 0.0).toDouble(),
      climbSuccessProb: (json['climbSuccessProb'] ?? 0.0).toDouble(),
      batteries: json['batteries'] ?? 0,
      framePerimeter: json['framePerimeter'] ?? '',
      shootingRate: (json['shootingRate'] ?? 0.0).toDouble(),
      hopperSealed: json['hopperSealed'] ?? false,
      trenchUnder: json['trenchUnder'] ?? '',
      bumpOver: json['bumpOver'] ?? false,
      driverYear: json['driverYear'] ?? 0,
      interviewerName: json['interviewerName'] ?? '',
      interviewerRole: json['interviewerRole'] ?? '',
      attitude: json['attitude'] ?? true,
      scoutingAccuracy: json['scoutingAccuracy'] ?? '',
      notCooperativeReason: json['notCooperativeReason'] ?? '',
      pathDraw: json['pathDraw'] != null
          ? List<dynamic>.from(json['pathDraw']).map((e) {
        if (e is Map) {
          return Map<String, String?>.from(
              e.map((k, v) => MapEntry(k.toString(), v?.toString()))
          );
        }
        // backward compat: old plain string entries get wrapped
        return <String, String?>{'name': null, 'path': e?.toString()};
      }).toList()
          : [],
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
    log(_storage as String);
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
      batteryPercentage: json['batteryPercentage'] ?? 0,
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
      batteryPercentage: map['batteryPercentage'] ?? 0,
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
      'batteryPercentage': record.batteryPercentage,
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
  final int batteryPercentage;

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
    required this.batteryPercentage,
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
      "batteryPercentage": batteryPercentage,
    };
  }

  String toCsv() {
    return '${teamNumber},${matchKey},${matchNumber},${scouterName},${allianceColor},${eventKey},${station},${batteryPercentage}, ${autonPoints.toCsv()}, ${teleOpPoints.toCsv()}, ${endPoints.toCsv()}';
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
      batteryPercentage: json['batteryPercentage'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'MatchRecord{batteryPercentage: $batteryPercentage, teamNumber: $teamNumber, scouterName: $scouterName, matchKey: $matchKey, autonPoints: $autonPoints, teleOpPoints: $teleOpPoints, endPoints: $endPoints, allianceColor: $allianceColor, eventKey: $eventKey, station: $station}';
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
        endPoints.hashCode ^
        batteryPercentage.hashCode;
  }
}

// AutonPoints
class AutonPoints {
  double total_shooting_time = 0;
  int amountOfShooting = 0;
  bool climb = false;
  int passing = 0;

  AutonPoints(
    this.total_shooting_time,
    this.amountOfShooting,
    this.climb,
    this.passing,
  );

  Map<String, dynamic> toJson() {
    return {
      "TotalShootingTime": total_shooting_time,
      "AmountOfShooting": amountOfShooting,
      "Climb": climb,
      "passing": passing
    };
  }

  String toCsv() {
    return '${total_shooting_time.toStringAsFixed(2)},$amountOfShooting,${climb ? 1 : 0},$passing';
  }

  static AutonPoints fromJson(Map<String, dynamic> json) {
    return AutonPoints(
      (json['TotalShootingTime'] ?? 0).toDouble(),
      _toInt(json["AmountOfShooting"]),
      json['Climb'] ?? false,
      _toInt(json['passing']),
    );
  }

  @override
  String toString() {
    return 'TotalShootingTime: $total_shooting_time, AmountOfShooting: $amountOfShooting, Climb: $climb, passing: $passing}';
  }

  void setTotalShootingTime(double value) {
    total_shooting_time = value;
  }

  setAmountOfShooting(int value) {
    amountOfShooting = value;
  }

  setClimb(bool value) {
    climb = value;
  }

  setPassing(int value) {
    passing = value;
  }
}

// TeleOpPoints
class TeleOpPoints {
  double TotalShootingTime1 = 0;
  int TotalAmount1 = 0;
  bool Defense = false;
  int NeutralTrips = 0;
  int PushBalls = 0;
  int passing = 0;

  TeleOpPoints(
      this.TotalShootingTime1,
      this.TotalAmount1,
      this.Defense,
      this.NeutralTrips,
      this.PushBalls,
      this.passing,);

  Map<String, dynamic> toJson() {
    return {
      "TotalShootingTime1": TotalShootingTime1,
      "TotalAmount1": TotalAmount1,
      "Defense": Defense,
      "NeutralTrips": NeutralTrips,
      "PushBalls": PushBalls,
      "passing": passing,
    };
  }

  String toCsv() {
    return '${TotalShootingTime1.toStringAsFixed(2)},${TotalAmount1},${Defense ? 1 : 0},${NeutralTrips},${PushBalls},${passing}';
  }

  static TeleOpPoints fromJson(Map<String, dynamic> json) {
    return TeleOpPoints(
      (json['TotalShootingTime1'] ?? json['TotalShootingTime'] ?? 0).toDouble(),
      _toInt(json['TotalAmount1']),
      json['Defense'] ?? false,
      _toInt(json['NeutralTrips'] ?? json['NeutralTips']),
      _toInt(json['PushBalls']),
      _toInt(json['passing']),
    );
  }

  @override
  String toString() {
    return 'TeleOpPoints{TotalShootingTime1: $TotalShootingTime1, TotalAmount1 $TotalAmount1, NeutralTips $NeutralTrips, Defense: $Defense, PushBalls: $PushBalls, passing: $passing}';
  }

  setTotalShootingTime1(double value) {
    TotalShootingTime1 = value;
  }

  setTotalAmount1(int value) {
    TotalAmount1 = value;
  }

  setNeutralTrips(int value) {
    NeutralTrips = value;
  }

  setDefense(bool value) {
    Defense = value;
  }

  setPushBalls(int value) {
    PushBalls = value;
  }

  setPassing(int value) {
    passing = value;
  }

}

// EndPoints
class EndPoints {
  // 0 = None, 1-9 = Level IDs (L/M/R for Levels 1-3)
  int ClimbStatus = 0;
  bool Park = false;
  int PushBallsEnd = 0;
  int Passing = 0;
  bool robotBroken = false;
  int EndNeutralTrips = 0;
  int ShootingAccuracy;
  double endgameTime;
  int endgameshootingCycles;
  String Comments = '';

  EndPoints(
    this.ClimbStatus,
    this.Park,
    this.PushBallsEnd,
    this.Passing,
    this.robotBroken,
    this.EndNeutralTrips,
    this.ShootingAccuracy,
    this.endgameTime,
    this.endgameshootingCycles,
      this.Comments,
  );

  Map<String, dynamic> toJson() {
    return {
      "ClimbStatus": ClimbStatus,
      "Park": Park,
      "PushBallsEnd": PushBallsEnd,
      "Passing": Passing,
      "EndNeutralTrips": EndNeutralTrips,
      "ShootingAccuracy": ShootingAccuracy,
      "endgameTime": endgameTime,
      "endgameshootingCycles": endgameshootingCycles,
      "robotBroken": robotBroken,
      "Comments": Comments,
    };
  }

  static EndPoints fromJson(Map<String, dynamic> json) {
    return EndPoints(
      _toInt(json['ClimbStatus']),
      json['Park'] ?? false,
      _toInt(json['PushBallsEnd']),
      _toInt(json['Passing']),
      json['robotBroken'] ?? false,
      _toInt(json['EndNeutralTrips']),
      _toInt(json['ShootingAccuracy'] ?? 3),
      (json['endgameTime'] ?? 0.0).toDouble(),
      _toInt(json['endgameshootingCycles']),
      json['Comments'] ?? '',
      // Handle both list and legacy string/migration
    );
  }

  @override
  String toString() {
    return 'EndPoints{ClimbStatus: $ClimbStatus, Park: $Park, PushBallsEnd: $PushBallsEnd, Passing: $Passing, EndNeutralTrips: $EndNeutralTrips, ShootingAccuracy: $ShootingAccuracy, endgameTime: $endgameTime, endgameshootingCycles: $endgameshootingCycles, robotBroken: $robotBroken,Comments: $Comments }';
  }

  String toCsv() {
    return '$ClimbStatus,${Park ? 1 : 0},${PushBallsEnd},$Passing,$EndNeutralTrips,$ShootingAccuracy,$endgameTime,$endgameshootingCycles,$robotBroken, "${Comments.replaceAll('"', '""')}"';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EndPoints &&
        other.ClimbStatus == ClimbStatus &&
        other.Park == Park &&
        other.EndNeutralTrips == EndNeutralTrips &&
        other.PushBallsEnd == PushBallsEnd &&
        other.Passing == Passing &&
        other.ShootingAccuracy == ShootingAccuracy &&
        other.endgameTime == endgameTime &&
        other.endgameshootingCycles == endgameshootingCycles &&
        other.robotBroken == robotBroken&&
        other.Comments == Comments;
  }

  @override
  int get hashCode {
    return ClimbStatus.hashCode ^
        Park.hashCode ^
        EndNeutralTrips.hashCode ^
        PushBallsEnd.hashCode ^
        Passing.hashCode ^
        ShootingAccuracy.hashCode ^
        endgameTime.hashCode ^
        endgameshootingCycles.hashCode ^
        robotBroken.hashCode^
        Comments.hashCode;
  }

  setClimbStatus(int value) {
    ClimbStatus = value;
  }

  setPark(bool value) {
    Park = value;
  }

  setShootingAccuracy(int value) {
    ShootingAccuracy = value;
  }

  setEndNeutralTrips(int value) {
    EndNeutralTrips = value;
  }

  setPushBallsEnd(int value) {
    PushBallsEnd = value;
  }

  setPassing(int value) {
    Passing = value;
  }

  setComments(String value) {
    Comments = value;
  }
}

class DrawingBitmaskCodec {
  static const int _rows = 33;
  static const int _cols = 58;
  static const int _totalCells = _rows * _cols; // 1914

  static String encode(List<int> ids) {
    if (ids.isEmpty) return '';

    int byteLength = (_totalCells + 7) >> 3;
    Uint8List bytes = Uint8List(byteLength);

    for (final id in ids) {
      if (id < 1 || id > _totalCells) continue;
      int index = id - 1;
      int byteIndex = index >> 3;
      int bitIndex = index & 7;
      bytes[byteIndex] |= (1 << bitIndex);
    }

    return base64Url.encode(bytes);
  }

  static List<int> decode(String encoded) {
    if (encoded.isEmpty) return [];
    Uint8List bytes = base64Url.decode(encoded);
    List<int> ids = [];

    int maxBits = _totalCells;
    for (int index = 0; index < maxBits; index++) {
      int byteIndex = index >> 3;
      int bitIndex = index & 7;
      if (byteIndex >= bytes.length) break;
      if ((bytes[byteIndex] & (1 << bitIndex)) != 0) {
        ids.add(index + 1);
      }
    }

    return ids;
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
      (data['TotalShootingTime'] ?? 0).toDouble(),
      _toInt(data['aMOUNT OF SHOOTING']),
      data['Climb'] ?? false,
      _toInt(data['passing']),
    );
  }

  static TeleOpPoints fromJson(Map<String, dynamic> json) {
    return TeleOpPoints(
      (json['TotalShootingTime1'] ?? 0).toDouble(),
      _toInt(json['TotalAmount1'] ?? 0),
      json['Defense'] ?? false,
      _toInt(json['NeutralTrips'] ?? 0),
      _toInt(json['PushBallsEnd'] ?? 0),
      _toInt(json['passing'] ?? 0),
    );
  }

  static EndPoints mapToEndPoints(Map<dynamic, dynamic> data) {
    return EndPoints(
      _toInt(data['ClimbStatus']),
      data['Park'] ?? false,
      data['PushBallsEnd'] ?? 0,
      _toInt(data['Passing']),
      data['robotBroken'] ?? false,
      _toInt(data['EndNeutralTrips']),
      _toInt(data['ShootingAccuracy'] ?? 3),
      (data['EndgameTime'] ?? 0).toDouble(),
      _toInt(data['endgameshootingCycles']),
      data['Comments'] ?? '',
    );
  }

  static PitRecord mapToPitRecord(Map<dynamic, dynamic> data) {
    return PitRecord(
        teamNumber: data['teamNumber'] ?? 0,
        eventKey: data['eventKey'] ?? "",
        scouterName: data['scouterName'] ?? "",
        driveTrainType: data['driveTrainType'] ?? "",
        autonType: data['auton'] ?? "",
        scoreObject: List<String>.from(data['scoreObject'] ?? []),
        climbType: List<String>.from(data['climbType'] ?? []),
        scoreType: List<String>.from(data['scoreType'] ?? []),
        botImage1: data['botImage1'] ?? "",
        botImage2: data['botImage2'] ?? "",
        botImage3: data['botImage3'] ?? "",);
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
    return '${position.dx.toStringAsFixed(1)},${position.dy.toStringAsFixed(1)},${size.width.toStringAsFixed(1)},${size.height.toStringAsFixed(1)},${angle.toStringAsFixed(1)}';
  }
}

class PitChecklistItem {
  String note = "";
  String matchkey = "";

  double returning_battery_voltage = 0.0;
  double returning_battery_cca = 0.0;
  double returning_number = 0.0;
  double outgoing_battery_voltage = 0.0;
  double outgoing_battery_cca = 0.0;
  double outgoing_number = 0.0;
  bool outgoing_battery_replaced = false;

  //drivetrain
  bool drive_motors = false;
  bool drive_wheels = false;
  bool drive_gearboxes = false;
  bool drive_encoders = false;
  bool drive_wires = false;
  bool drive_lime_lights = false;
  bool drive_nuts_and_bolts = false;
  bool drive_steer_motors = false;

  //structure
  bool structure_frame = false;
  bool structure_hopper_panels = false;
  bool structure_brain_pan = false;
  bool structure_belly_pan = false;
  bool structure_nuts_and_bolts = false;

  //intake
  bool intake_rack = false;
  bool intake_pinion = false;
  bool intake_belts = false;
  bool intake_roller = false;
  bool intake_boot = false; // New field for Boot
  bool intake_motors = false;
  bool intake_limit_switches = false;
  bool intake_lime_lights = false;
  bool intake_nuts_and_bolts = false;
  bool intake_wires = false;

  //spindexer
  bool spindexer_panel = false;
  bool spindexer_churros = false;
  bool spindexer_3d_prints = false; // New field for 3D Prints
  bool spindexer_motor = false;
  bool spindexer_wheels = false;
  bool spindexer_nuts_and_bolts = false;

  //kicker
  bool kicker_plates = false;
  bool kicker_roller = false;
  bool kicker_belts = false;
  bool kicker_gears = false;
  bool kicker_motor = false;
  bool kicker_radio = false;
  bool kicker_ethernet_switch = false;
  bool kicker_nuts_and_bolts = false;
  bool kicker_wires = false;

  //shooter
  bool shooter_flywheels = false;
  bool shooter_hood = false;
  bool shooter_hood_gears = false;
  bool shooter_gears = false;
  bool shooter_motors = false;
  bool shooter_nuts_and_bolts = false;
  bool shooter_wires = false;

  String alliance_color = "Blue";
  Map<String, dynamic>? alliance_selection_data;
  String img1 = "";
  String img2 = "";
  String img3 = "";
  String img4 = "";
  String img5 = "";

  PitChecklistItem({
    required this.matchkey,
    required this.returning_battery_voltage,
    required this.returning_battery_cca,
    required this.returning_number,
    required this.outgoing_battery_voltage,
    required this.outgoing_battery_cca,
    required this.outgoing_number,
    required this.outgoing_battery_replaced,
    //drivetrain
    required this.drive_motors,
    required this.drive_wheels,
    required this.drive_gearboxes,
    required this.drive_encoders,
    required this.drive_wires,
    required this.drive_lime_lights,
    required this.drive_nuts_and_bolts,
    required this.drive_steer_motors,
    //structure
    required this.structure_frame,
    required this.structure_hopper_panels,
    required this.structure_brain_pan,
    required this.structure_belly_pan,
    required this.structure_nuts_and_bolts,
    //intake
    required this.intake_rack,
    required this.intake_pinion,
    required this.intake_belts,
    required this.intake_roller,
    required this.intake_boot, // New required field
    required this.intake_motors,
    required this.intake_limit_switches,
    required this.intake_lime_lights,
    required this.intake_nuts_and_bolts,
    required this.intake_wires,
    //spindexer
    required this.spindexer_panel,
    required this.spindexer_churros,
    required this.spindexer_3d_prints, // New required field
    required this.spindexer_motor,
    required this.spindexer_wheels,
    required this.spindexer_nuts_and_bolts,
    //kicker
    required this.kicker_plates,
    required this.kicker_roller,
    required this.kicker_belts,
    required this.kicker_gears,
    required this.kicker_motor,
    required this.kicker_radio,
    required this.kicker_ethernet_switch,
    required this.kicker_nuts_and_bolts,
    required this.kicker_wires,
    //shooter
    required this.shooter_flywheels,
    required this.shooter_hood,
    required this.shooter_hood_gears,
    required this.shooter_gears,
    required this.shooter_motors,
    required this.shooter_nuts_and_bolts,
    required this.shooter_wires,
    required this.img1,
    required this.img2,
    required this.img3,
    required this.img4,
    required this.img5,
    required this.alliance_color,
    required this.note,
    this.alliance_selection_data,
  });

  PitChecklistItem.defaultConstructor(String matchkey) {
    this.matchkey = matchkey;
  }

  String to_Csv() {
    return '$matchkey,'
        '$returning_battery_voltage,$returning_battery_cca,$returning_number,'
        '$outgoing_battery_voltage,$outgoing_battery_cca,$outgoing_number,$outgoing_battery_replaced,'
        //drivetrain
        '$drive_motors,$drive_wheels,$drive_gearboxes,$drive_encoders,$drive_wires,$drive_lime_lights,$drive_nuts_and_bolts,$drive_steer_motors,'
        //structure
        '$structure_frame,$structure_hopper_panels,$structure_brain_pan,$structure_belly_pan,$structure_nuts_and_bolts'
        //intake
        '$intake_rack,$intake_pinion,$intake_belts,$intake_roller,$intake_boot,$intake_motors,$intake_limit_switches,$intake_lime_lights,$intake_nuts_and_bolts,$intake_wires,'
        //spindexer
        '$spindexer_panel,$spindexer_churros,$spindexer_3d_prints,$spindexer_motor,$spindexer_wheels,$spindexer_nuts_and_bolts'
        //kicker
        '$kicker_plates,$kicker_roller,$kicker_belts,$kicker_gears,$kicker_motor,$kicker_radio,$kicker_ethernet_switch,$kicker_nuts_and_bolts,$kicker_wires,'
        //shooter
        '$shooter_flywheels,$shooter_hood,$shooter_hood_gears,$shooter_gears,$shooter_motors,$shooter_nuts_and_bolts,$shooter_wires,'
        '$alliance_color';
  }

  Map<String, dynamic> toJson() {
    return {
      'matchkey': matchkey,

      'returning_battery_voltage': returning_battery_voltage,
      'returning_battery_cca': returning_battery_cca,
      'returning_number': returning_number,
      'outgoing_battery_voltage': outgoing_battery_voltage,
      'outgoing_battery_cca': outgoing_battery_cca,
      'outgoing_number': outgoing_number,
      'outgoing_battery_replaced': outgoing_battery_replaced,
      //drivetrain
      'drive_motors': drive_motors,
      'drive_wheels': drive_wheels,
      'drive_gearboxes': drive_gearboxes,
      'drive_encoders': drive_encoders,
      'drive_wires': drive_wires,
      'drive_lime_lights': drive_lime_lights,
      'drive_nuts_and_bolts': drive_nuts_and_bolts,
      'drive_steer_motors': drive_steer_motors,
      //structure
      'structure_frame': structure_frame,
      'structure_hopper_panels': structure_hopper_panels,
      'structure_brain_pan': structure_brain_pan,
      'structure_belly_pan': structure_belly_pan,
      'structure_nuts_and_bolts': structure_nuts_and_bolts,
      //intake
      'intake_rack': intake_rack,
      'intake_pinion': intake_pinion,
      'intake_belts': intake_belts,
      'intake_roller': intake_roller,
      'intake_boot': intake_boot,
      'intake_motors': intake_motors,
      'intake_limit_switches': intake_limit_switches,
      'intake_lime_lights': intake_lime_lights,
      'intake_nuts_and_bolts': intake_nuts_and_bolts,
      'intake_wires': intake_wires,
      //spindexer
      'spindexer_panel': spindexer_panel,
      'spindexer_churros': spindexer_churros,
      'spindexer_3d_prints': spindexer_3d_prints,
      'spindexer_motor': spindexer_motor,
      'spindexer_wheels': spindexer_wheels,
      'spindexer_nuts_and_bolts': spindexer_nuts_and_bolts,
      //kicker
      'kicker_plates': kicker_plates,
      'kicker_roller': kicker_roller,
      'kicker_belts': kicker_belts,
      'kicker_gears': kicker_gears,
      'kicker_motor': kicker_motor,
      'kicker_radio': kicker_radio,
      'kicker_ethernet_switch': kicker_ethernet_switch,
      'kicker_nuts_and_bolts': kicker_nuts_and_bolts,
      'kicker_wires': kicker_wires,
      //shooter
      'shooter_flywheels': shooter_flywheels,
      'shooter_hood': shooter_hood,
      'shooter_hood_gears': shooter_hood_gears,
      'shooter_gears': shooter_gears,
      'shooter_motors': shooter_motors,
      'shooter_nuts_and_bolts': shooter_nuts_and_bolts,
      'shooter_wires': shooter_wires,

      'alliance_color': alliance_color,
      'note': note,
      'alliance_selection_data': alliance_selection_data,
      'img1': img1,
      'img2': img2,
      'img3': img3,
      'img4': img4,
      'img5': img5,
    };
  }

  factory PitChecklistItem.fromJson(Map<String, dynamic> json) =>
      PitChecklistItem(
        note: json['note'] ?? "",
        matchkey: json['matchkey'] ?? " ",

        returning_battery_voltage:
            (json['returning_battery_voltage'] ?? 0.0).toDouble(),
        returning_battery_cca:
            (json['returning_battery_cca'] ?? 0.0).toDouble(),
        returning_number: (json['returning_number'] ?? 0.0).toDouble(),
        outgoing_battery_voltage:
            (json['outgoing_battery_voltage'] ?? 0.0).toDouble(),
        outgoing_battery_cca: (json['outgoing_battery_cca'] ?? 0.0).toDouble(),
        outgoing_number: (json['outgoing_number'] ?? 0.0).toDouble(),
        outgoing_battery_replaced: json['outgoing_battery_replaced'] ?? false,
        //drivetrain
        drive_motors: json['drive_motors'] ?? false,
        drive_wheels: json['drive_wheels'] ?? false,
        drive_gearboxes: json['drive_gearboxes'] ?? false,
        drive_encoders: json['drive_encoders'] ?? false,
        drive_wires: json['drive_wires'] ?? false,
        drive_lime_lights: json['drive_lime_lights'] ?? false,
        drive_nuts_and_bolts: json['drive_nuts_and_bolts'] ?? false,
        drive_steer_motors: json['drive_steer_motors'] ?? false,
        //structure
        structure_frame: json['structure_frame'] ?? false,
        structure_hopper_panels: json['structure_hopper_panels'] ?? false,
        structure_brain_pan: json['structure_brain_pan'] ?? false,
        structure_belly_pan: json['structure_belly_pan'] ?? false,
        structure_nuts_and_bolts: json['structure_nuts_and_bolts'] ?? false,
        //intake
        intake_rack: json['intake_rack'] ?? false,
        intake_pinion: json['intake_pinion'] ?? false,
        intake_belts: json['intake_belts'] ?? false,
        intake_roller: json['intake_roller'] ?? false,
        intake_boot: json['intake_boot'] ?? false,
        intake_motors: json['intake_motors'] ?? false,
        intake_limit_switches: json['intake_limit_switches'] ?? false,
        intake_lime_lights: json['intake_lime_lights'] ?? false,
        intake_nuts_and_bolts: json['intake_nuts_and_bolts'] ?? false,
        intake_wires: json['intake_wires'] ?? false,
        //spindexer
        spindexer_panel: json['spindexer_panel'] ?? false,
        spindexer_churros: json['spindexer_churros'] ?? false,
        spindexer_3d_prints: json['spindexer_3d_prints'] ?? false,
        spindexer_motor: json['spindexer_motor'] ?? false,
        spindexer_wheels: json['spindexer_wheels'] ?? false,
        spindexer_nuts_and_bolts: json['spindexer_nuts_and_bolts'] ?? false,
        //kicker
        kicker_plates: json['kicker_plates'] ?? false,
        kicker_roller: json['kicker_roller'] ?? false,
        kicker_belts: json['kicker_belts'] ?? false,
        kicker_gears: json['kicker_gears'] ?? false,
        kicker_motor: json['kicker_motor'] ?? false,
        kicker_radio: json['kicker_radio'] ?? false,
        kicker_ethernet_switch: json['kicker_ethernet_switch'] ?? false,
        kicker_nuts_and_bolts: json['kicker_nuts_and_bolts'] ?? false,
        kicker_wires: json['kicker_wires'] ?? false,
        //shooter
        shooter_flywheels: json['shooter_flywheels'] ?? false,
        shooter_hood: json['shooter_hood'] ?? false,
        shooter_hood_gears: json['shooter_hood_gears'] ?? false,
        shooter_gears: json['shooter_gears'] ?? false,
        shooter_motors: json['shooter_motors'] ?? false,
        shooter_nuts_and_bolts: json['shooter_nuts_and_bolts'] ?? false,
        shooter_wires: json['shooter_wires'] ?? false,

        img1: json['img1'] ?? "",
        img2: json['img2'] ?? "",
        img3: json['img3'] ?? "",
        img4: json['img4'] ?? "",
        img5: json['img5'] ?? "",
        alliance_color: json['alliance_color'] ?? "",
        alliance_selection_data: json['alliance_selection_data'],
      );
}

class PitCheckListDatabase {
  static final Map<String, PitChecklistItem> _storage = {};

  static void PutData(dynamic key, PitChecklistItem value) {
    if (key == null) {
      throw Exception('Key cannot be null');
    }

    // print(' Storing $key as $value');
    _storage[key.toString()] = value;
  }

  static PitChecklistItem? GetData(dynamic key) {
    // print('Retrieving $key as ${_storage[key]}');
    if (_storage[key.toString()] == null) {
      return null;
    }

    // Convert the stored data to a PitRecord object
    var data = _storage[key.toString()];
    if (data is PitChecklistItem) {
      return data;
    } else if (data is Map<String, dynamic>) {
      // ignore: cast_from_null_always_fails
      return PitChecklistItem.fromJson(data as Map<String, dynamic>);
    }

    return null;
  }

  static void DeleteData(String key) {
    // print('Deleting $key');
    _storage.remove(key);
  }

  static void ClearData() {
    // print('Clearing all data');
    Hive.box('pitcheck').put('data', null);
    _storage.clear();
  }

  static void SaveAll() {
    Hive.box('pitcheck').put('data', jsonEncode(_storage));
  }

  static void LoadAll() {
    var dd = Hive.box('pitcheck').get('data');
    if (dd != null) {
      Map<String, dynamic> data = json.decode(dd);
      data.forEach((key, value) {
        _storage[key] = value is Map
            ? PitChecklistItem.fromJson(value as Map<String, dynamic>)
            : value;
      });
    }
  }

  static void PrintAll() {
    log(_storage.toString());
  }

  static Map<String, double> getMostRecentBatteryInfo() {
    LoadAll();
    double latestBatteryNumber = 0.0;
    double latestBatteryVoltage = 0.0;
    int highestMatch = -1;
    for (var record in _storage.values) {
      final RegExp regExp = RegExp(r'(?:qm|sf|qf|f)(\d+)');
      final match = regExp.firstMatch(record.matchkey);
      if (match != null) {
        int mNum = int.parse(match.group(1)!);
        if (mNum > highestMatch && record.outgoing_number != 0.0) {
          highestMatch = mNum;
          latestBatteryNumber = record.outgoing_number;
          latestBatteryVoltage = record.outgoing_battery_voltage;
        }
      }
    }
    return {'number': latestBatteryNumber, 'voltage': latestBatteryVoltage};
  }

  static List<dynamic> GetRecorderTeam() {
    // Change return type to List<dynamic>
    List<dynamic> teams = [];
    _storage.forEach((key, value) {
      teams.add(value.matchkey);
    });
    return teams;
  }

  static dynamic Export() {
    return _storage;
  }

  static void Import(Map<String, dynamic> data) {
    data.forEach((key, value) {
      _storage[key] = value is Map
          ? PitChecklistItem.fromJson(value as Map<String, dynamic>)
          : value;
    });
  }

  static void ImportFromJson(String jsonString) {
    Map<String, dynamic> data = json.decode(jsonString);
    Import(data);
  }

  static String ExportAsJson() {
    // Convert the internal storage to JSON string
    Map<String, dynamic> exportData = {};

    _storage.forEach((key, value) {
      exportData[key] = value.toJson();
    });

    return jsonEncode(exportData);
  }

  static int GetStorageSize() {
    return _storage.length;
  }

  static List<String> GetKeys() {
    return _storage.keys.toList();
  }

  static Future<void> BackupToFile(String fileName) async {
    try {
      final String jsonData = ExportAsJson();
      // Implementation would depend on file access method (would need to import dart:io)
      // Example placeholder:
      final file = File(fileName);
      await file.writeAsString(jsonData);
      log('Backup completed to: $fileName');
    } catch (e) {
      log('Error backing up data: $e');
      throw Exception('Failed to backup data: $e');
    }
  }

  static Future<bool> RestoreFromFile(String fileName) async {
    try {
      // Implementation would depend on file access method
      // Example placeholder:
      final file = File(fileName);
      if (await file.exists()) {
        final String jsonData = await file.readAsString();
        ImportFromJson(jsonData);
        return true;
      }
      return false;
    } catch (e) {
      log('Error restoring data: $e');
      return false;
    }
  }
}
