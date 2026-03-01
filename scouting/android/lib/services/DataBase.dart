import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

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
  final List<String> intake;
  final List<String> climbType;
  final String botImage1;
  final String botImage2;
  final String botImage3;

  PitRecord(
      {required this.teamNumber,
      required this.scouterName,
      required this.eventKey,
      required this.driveTrainType,
      required this.autonType,
      required this.scoreObject,
      required this.scoreType,
      required this.intake,
      required this.climbType,
      required this.botImage1,
      required this.botImage2,
      required this.botImage3});

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
      "botImage1": botImage1,
      "botImage2": botImage2,
      "botImage3": botImage3
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
      intake: List<String>.from(parseIntake()),
      climbType:
          json['climbType'] is List ? List<String>.from(json['climbType']) : [],

      botImage1: json['botImage1'] ?? '',
      botImage2: json['botImage2'] ?? '',
      botImage3: json['botImage3'] ?? '',
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
    return '${batteryPercentage},${teamNumber},${scouterName},${matchKey},${allianceColor},${eventKey},${station},${matchNumber}, ${autonPoints.toCsv()}, ${teleOpPoints.toCsv()}, ${endPoints.toCsv()}';
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
  bool fuel_pickup_from_Depot = false;
  bool fuel_pickup_from_Outpost = false;
  bool fuel_pickup_from_Neutral_Zone = false;
  bool left_starting_position = false;
  double total_shooting_time = 0;
  int amountOfShooting = 0;
  bool climb = false;
  String winAfterAuton = "";
  BotLocation starting_location;

  AutonPoints(
    this.fuel_pickup_from_Depot,
    this.fuel_pickup_from_Outpost,
    this.fuel_pickup_from_Neutral_Zone,
    this.total_shooting_time,
    this.amountOfShooting,
    this.climb,
    this.winAfterAuton,
    this.starting_location,
    this.left_starting_position,
  );

  Map<String, dynamic> toJson() {
    return {
      "FuelPickUpFromDepot": fuel_pickup_from_Depot,
      "FuelPickUpFromOutpost": fuel_pickup_from_Outpost,
      "FuelPickUpFromNeutralZone": fuel_pickup_from_Neutral_Zone,
      "TotalShootingTime": total_shooting_time,
      "AmountOfShooting": amountOfShooting,
      "Climb": climb,
      "WinAfterAuton": winAfterAuton,
      "RobotLocation": starting_location.toJson(),
      "LeftStartingPosition": left_starting_position
    };
  }

  String toCsv() {
    return '${left_starting_position ? 1 : 0},${fuel_pickup_from_Depot ? 1 : 0},${fuel_pickup_from_Outpost ? 1 : 0},${fuel_pickup_from_Neutral_Zone ? 1 : 0},$total_shooting_time,$amountOfShooting,${climb ? 1 : 0},$winAfterAuton,${starting_location.toCsv()}';
  }

  static AutonPoints fromJson(Map<String, dynamic> json) {
    return AutonPoints(
      json['FuelPickUpFromDepot'] ?? false,
      json['FuelPickUpFromOutpost'] ?? false,
      json['FuelPickUpFromNeutralZone'] ?? false,
      json['TotalShootingTime'] ?? 0,
      json["AmountOfShooting"] ?? 0,
      json['Climb'] ?? false,
      json['WinAfterAuton'] ?? "",
      BotLocation.fromJson(
        json['RobotLocation'] ??
            {
              'position': {'x': 0.0, 'y': 0.0},
              'size': {'width': 0.0, 'height': 0.0},
              'angle': 0.0
            },
      ),
      json['LeftStartingPosition'] ?? false,
    );
  }

  @override
  String toString() {
    return 'AutonPoints{FuelPickUpFromDepot: $fuel_pickup_from_Depot, FuelPickUpFromOutpost: $fuel_pickup_from_Outpost, FuelPickUpFromNeutralZone: $fuel_pickup_from_Neutral_Zone, TotalShootingTime: $total_shooting_time, AmountOfShooting: $amountOfShooting, Climb: $climb, WinAfterAuton: $winAfterAuton, LeftStartingPosition: $left_starting_position, RobotLocation: $starting_location}';
  }

  void setFuelPickupFromDepot(bool value) {
    fuel_pickup_from_Depot = value;
  }

  setFuelPickupFromOutpost(bool value) {
    fuel_pickup_from_Outpost = value;
  }

  setFuelPickUpFromNeutralZone(bool value) {
    fuel_pickup_from_Neutral_Zone = value;
  }

  setTotalShootingTime(double value) {
    total_shooting_time = value;
  }

  setAmountOfShooting(int value) {
    amountOfShooting = value;
  }

  setClimb(bool value) {
    climb = value;
  }

  setWinAfterAuton(String value) {
    winAfterAuton = value;
  }

  setStartingLocation(BotLocation value) {
    starting_location = value;
  }
}

// TeleOpPoints
class TeleOpPoints {
  double TotalShootingTime1 = 0;
  double TotalShootingTimeA1 = 0;
  double TotalShootingTimeA2 = 0;
  bool ShootingI1 = false;
  bool ShootingI2 = false;
  int TotalAmount1 = 0;
  int TotalAmountA1 = 0;
  int TotalAmountA2 = 0;
  int TotalAmountI1 = 0;
  int TotalAmountI2 = 0;
  int TripAmount1 = 0;
  bool Defense = false;
  bool DefenseA1 = false;
  bool DefenseA2 = false;
  bool DefenseI1 = false;
  bool DefenseI2 = false;
  int NeutralTrips = 0;
  int NeutralTripsA1 = 0;
  int NeutralTripsA2 = 0;
  int NeutralTripsI1 = 0;
  int NeutralTripsI2 = 0;
  bool FeedToHPStation = false;
  bool FeedToHPStationA1 = false;
  bool FeedToHPStationA2 = false;
  bool FeedToHPStationI1 = false;
  bool FeedToHPStationI2 = false;
  bool passing = false;
  bool passingA1 = false;
  bool passingA2 = false;
  bool passingI1 = false;
  bool passingI2 = false;

  TeleOpPoints(
      this.TotalShootingTime1,
      this.TotalShootingTimeA1,
      this.TotalShootingTimeA2,
      this.ShootingI1,
      this.ShootingI2,
      this.TotalAmount1,
      this.TotalAmountA1,
      this.TotalAmountA2,
      this.TotalAmountI1,
      this.TotalAmountI2,
      this.TripAmount1,
      this.Defense,
      this.DefenseA1,
      this.DefenseA2,
      this.DefenseI1,
      this.DefenseI2,
      this.NeutralTrips,
      this.NeutralTripsA1,
      this.NeutralTripsA2,
      this.NeutralTripsI1,
      this.NeutralTripsI2,
      this.FeedToHPStation,
      this.FeedToHPStationA1,
      this.FeedToHPStationA2,
      this.FeedToHPStationI1,
      this.FeedToHPStationI2,
      this.passing,
      this.passingA1,
      this.passingA2,
      this.passingI1,
      this.passingI2);

  Map<String, dynamic> toJson() {
    return {
      "TotalShootingTime1": TotalShootingTime1,
      "TotalShootingTimeA1": TotalShootingTimeA1,
      "TotalShootingTimeA2": TotalShootingTimeA2,
      "ShootingI1": ShootingI1,
      "ShootingI2": ShootingI2,
      "TotalAmount1": TotalAmount1,
      "TotalAmountA1": TotalAmountA1,
      "TotalAmountA2": TotalAmountA2,
      "TotalAmountI1": TotalAmountI1,
      "TotalAmountI2": TotalAmountI2,
      "TripAmount1": TripAmount1,
      "Defense": Defense,
      "DefenseA1": DefenseA1,
      "DefenseA2": DefenseA2,
      "DefenseI1": DefenseI1,
      "DefenseI2": DefenseI2,
      "NeutralTips": NeutralTrips,
      "NeutralTipsA1": NeutralTripsA1,
      "NeutralTipsA2": NeutralTripsA2,
      "NeutralTipsI1": NeutralTripsI1,
      "NeutralTipsI2": NeutralTripsI2,
      "FeedToHPStation": FeedToHPStation,
      "FeedToHPStationA1": FeedToHPStationA1,
      "FeedToHPStationA2": FeedToHPStationA2,
      "FeedToHPStationI1": FeedToHPStationI1,
      "FeedToHPStationI2": FeedToHPStationI2,
      "passing": passing,
      "passingA1": passingA1,
      "passingA2": passingA2,
      "passingI1": passingI1,
      "passingI2": passingI2,
    };
  }

  String toCsv() {
    return '${TotalShootingTime1},${TotalShootingTimeA1},${TotalShootingTimeA2},${ShootingI1 ? 1 : 0},${ShootingI2 ? 1 : 0},${TotalAmount1},${TotalAmountA1},${TotalAmountA2},${TotalAmountI1},${TotalAmountI2},${TripAmount1},${NeutralTrips},${NeutralTripsA1},${NeutralTripsA2},${NeutralTripsI1},${NeutralTripsI2},${Defense ? 1 : 0},${DefenseA1 ? 1 : 0},${DefenseA2 ? 1 : 0},${DefenseI1 ? 1 : 0},${DefenseI2 ? 1 : 0},${FeedToHPStation ? 1 : 0},${FeedToHPStationA1 ? 1 : 0},${FeedToHPStationA2 ? 1 : 0},${FeedToHPStationI1 ? 1 : 0},${FeedToHPStationI2 ? 1 : 0},${passing ? 1 : 0},${passingA1 ? 1 : 0},${passingA2 ? 1 : 0},${passingI1 ? 1 : 0},${passingI2 ? 1 : 0}';
  }

  static TeleOpPoints fromJson(Map<String, dynamic> json) {
    return TeleOpPoints(
      (json['TotalShootingTime1'] ?? json['TotalShootingTime'] ?? 0).toDouble(),
      (json['TotalShootingTimeA1'] ?? 0).toDouble(),
      (json['TotalShootingTimeA2'] ?? 0).toDouble(),
      json['ShootingI1'] ?? false,
      json['ShootingI2'] ?? false,
      json['TotalAmount1'] ?? 0,
      json['TotalAmountA1'] ?? 0,
      json['TotalAmountA2'] ?? 0,
      json['TotalAmountI1'] ?? 0,
      json['TotalAmountI2'] ?? 0,
      json['TripAmount1'] ?? 0,
      json['Defense'] ?? false,
      json['DefenseA1'] ?? false,
      json['DefenseA2'] ?? false,
      json['DefenseI1'] ?? false,
      json['DefenseI2'] ?? false,
      json['NeutralTrips'] ?? json['NeutralTips'] ?? 0,
      json['NeutralTripsA1'] ?? json['NeutralTipsA1'] ?? 0,
      json['NeutralTripsA2'] ?? json['NeutralTipsA2'] ?? 0,
      json['NeutralTripsI1'] ?? json['NeutralTipsI1'] ?? 0,
      json['NeutralTripsI2'] ?? json['NeutralTipsI2'] ?? 0,
      json['FeedToHPStation'] ?? false,
      json['FeedToHPStationA1'] ?? false,
      json['FeedToHPStationA2'] ?? false,
      json['FeedToHPStationI1'] ?? false,
      json['FeedToHPStationI2'] ?? false,
      json['passing'] ?? false,
      json['passingA1'] ?? false,
      json['passingA2'] ?? false,
      json['passingI1'] ?? false,
      json['passingI2'] ?? false,
    );
  }

  @override
  String toString() {
    return 'TeleOpPoints{TotalShootingTime1: $TotalShootingTime1, TotalShootingTimeA1: $TotalShootingTimeA1, TotalShootingTimeA2: $TotalShootingTimeA2, ShootingI1: $ShootingI1, ShootingI2: $ShootingI2, TotalAmount1 $TotalAmount1, TotalAmountA1 $TotalAmountA1, TotalAmountA2 $TotalAmountA2, TotalAmountI1 $TotalAmountI1, TotalAmountI2 $TotalAmountI2, TripAmount1 $TripAmount1, NeutralTips $NeutralTrips, NeutralTipsA1 $NeutralTripsA1, NeutralTipsA2 $NeutralTripsA2, NeutralTipsI1 $NeutralTripsI1, NeutralTipsI2 $NeutralTripsI2, Defense: $Defense DefenseA1: $DefenseA1, DefenseA2: $DefenseA2, DefenseI1: $DefenseI1, DefenseI2: $DefenseI2, FeedToHPStation: $FeedToHPStation FeedToHPStationA1: $FeedToHPStationA1, FeedToHPStationA2: $FeedToHPStationA2 FeedToHPStationI1: $FeedToHPStationI1, FeedToHPStationI2: $FeedToHPStationI2, passing: $passing, passingA1: $passingA1, passingA2: $passingA2, passingI1: $passingI1 passingI2: $passingI2}';
  }

  setTotalShootingTime1(double value) {
    TotalShootingTime1 = value;
  }

  setTotalShootingTimeA1(double value) {
    TotalShootingTimeA1 = value;
  }

  setTotalShootingTimeA2(double value) {
    TotalShootingTimeA2 = value;
  }

  setShootingI1(bool value) {
    ShootingI1 = value;
  }

  setShootingI2(bool value) {
    ShootingI2 = value;
  }

  setTotalAmount1(int value) {
    TotalAmount1 = value;
  }

  setTotalAmountA1(int value) {
    TotalAmountA1 = value;
  }

  setTotalAmountA2(int value) {
    TotalAmountA2 = value;
  }

  setTotalAmountI1(int value) {
    TotalAmountI1 = value;
  }

  setTotalAmountI2(int value) {
    TotalAmountI2 = value;
  }

  setTripAmount1(int value) {
    TripAmount1 = value;
  }

  setNeutralTrips(int value) {
    NeutralTrips = value;
  }

  setNeutralTripsA1(int value) {
    NeutralTripsA1 = value;
  }

  setNeutralTripsA2(int value) {
    NeutralTripsA2 = value;
  }

  setNeutralTripsI1(int value) {
    NeutralTripsI1 = value;
  }

  setNeutralTripsI2(int value) {
    NeutralTripsI2 = value;
  }

  setDefense(bool value) {
    Defense = value;
  }

  setDefenseA1(bool value) {
    DefenseA1 = value;
  }

  setDefenseA2(bool value) {
    DefenseA2 = value;
  }

  setDefenseI1(bool value) {
    DefenseI1 = value;
  }

  setDefenseI2(bool value) {
    DefenseI2 = value;
  }

  setFeedToHPStation(bool value) {
    FeedToHPStation = value;
  }

  setFeedToHPStationA1(bool value) {
    FeedToHPStationA1 = value;
  }

  setFeedToHPStationA2(bool value) {
    FeedToHPStationA2 = value;
  }

  setFeedToHPStationI1(bool value) {
    FeedToHPStationI1 = value;
  }

  setFeedToHPStationI2(bool value) {
    FeedToHPStationI2 = value;
  }

  setPassing(bool value) {
    passing = value;
  }

  setPassingA1(bool value) {
    passingA1 = value;
  }

  setPassingA2(bool value) {
    passingA2 = value;
  }

  setPassingI1(bool value) {
    passingI1 = value;
  }

  setPassingI2(bool value) {
    passingI2 = value;
  }
}

// EndPoints
class EndPoints {
  // 0 = None, 1-9 = Level IDs (L/M/R for Levels 1-3)
  int ClimbStatus = 0;
  bool Park = false;
  bool FeedToHP = false;
  bool Passing = false;
  int EndNeutralTrips =0;
  int ShootingAccuracy;
  double endgameTime;
  int endgameActions;
  String Comments = '';
  List<int> drawingData = [];

  EndPoints(
    this.ClimbStatus,
    this.Park,
    this.FeedToHP,
    this.Passing,
    this.Comments,
    this.EndNeutralTrips,
    this.ShootingAccuracy,
    this.endgameTime,
    this.endgameActions,
    this.drawingData,
  );

  Map<String, dynamic> toJson() {
    return {
      "ClimbStatus": ClimbStatus,
      "Park": Park,
      "FeedToHP": FeedToHP,
      "Passing": Passing,
      "EndNeutralTrips": EndNeutralTrips,
      "ShootingAccuracy": ShootingAccuracy,
      "endgameTime": endgameTime,
      "endgameActions": endgameActions,
      "Comments": Comments,
      "DrawingData": drawingData,
    };
  }

  static EndPoints fromJson(Map<String, dynamic> json) {
    return EndPoints(
      json['ClimbStatus'] ?? 0,
      json['Park'] ?? false,
      json['FeedToHP'] ?? false,
      json['Passing'] ?? false,
      json['Comments'] ?? '',
      json['EndNeutralTrips'] ?? 0,
      (json['ShootingAccuracy'] as int?) ?? 3,
      (json['endgameTime'] ?? 0.0).toDouble(),
      json['endgameActions'] ?? 0,
      // Handle both list and legacy string/migration
      (json['DrawingData'] is List) ? List<int>.from(json['DrawingData']) : [],
    );
  }

  @override
  String toString() {
    return 'EndPoints{ClimbStatus: $ClimbStatus, Park: $Park, FeedToHP: $FeedToHP, Passing: $Passing, EndNeutralTrips: $EndNeutralTrips, ShootingAccuracy: $ShootingAccuracy, endgameTime: $endgameTime, endgameActions: $endgameActions, Comments: $Comments, DrawingData: $drawingData}';
  }

  String toCsv() {
    return '$ClimbStatus,${Park ? 1 : 0},${FeedToHP ? 1 : 0},${Passing ? 1 : 0},$EndNeutralTrips, $ShootingAccuracy,$endgameTime,$Comments,$drawingData';
  }

  String _encodeDrawingData() {
    return DrawingBitmaskCodec.encode(drawingData);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EndPoints &&
        other.ClimbStatus == ClimbStatus &&
        other.Park == Park &&
        other.EndNeutralTrips == EndNeutralTrips &&
        other.FeedToHP == FeedToHP &&
        other.Passing == Passing &&
        other.ShootingAccuracy == ShootingAccuracy &&
        other.Comments == Comments;
  }

  @override
  int get hashCode {
    return ClimbStatus.hashCode ^
        Park.hashCode ^
        EndNeutralTrips.hashCode ^
        FeedToHP.hashCode ^
        Passing.hashCode ^
        ShootingAccuracy.hashCode ^
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

  setFeedToHP(bool value) {
    FeedToHP = value;
  }

  setPassing(bool value) {
    Passing = value;
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
      data['FuelPickUpFromDepot'] ?? false,
      data['FuelPickUpFromOutpost'] ?? false,
      data['FuelPickUpFromNeutralZone'] ?? false,
      data['TotalShootingTime'] ?? 0,
      data['aMOUNT OF SHOOTING'] ?? 0,
      data['Climb'] ?? false,
      data['WinAfterAuton'] ?? "",
      BotLocation.fromJson(
        data['RobotLocation'] ??
            {
              'position': {'x': 0.0, 'y': 0.0},
              'size': {'width': 0.0, 'height': 0.0},
              'angle': 0.0
            },
      ),
      true, // LeftStartingPosition, assuming default true or fetched differently if needed
    );
  }

  static TeleOpPoints fromJson(Map<String, dynamic> json) {
    return TeleOpPoints(
        (json['TotalShootingTime1'] ?? json['TotalShootingTime'] ?? 0)
            .toDouble(),
        (json['TotalShootingTimeA1'] ?? 0).toDouble(),
        (json['TotalShootingTimeA2'] ?? 0).toDouble(),
        (json['TotalShootingTimeI1'] ?? 0).toDouble(),
        (json['TotalShootingTimeI2'] ?? 0).toDouble(),
        json['TotalAmount1'] ?? 0,
        json['TotalAmountA1'] ?? 0,
        json['TotalAmountA2'] ?? 0,
        json['TotalAmountI1'] ?? 0,
        json['TotalAmountI2'] ?? 0,
        json['TripAmount1'] ?? 0,
        json['Defense'] ?? false,
        json['DefenseA1'] ?? false,
        json['DefenseA2'] ?? false,
        json['DefenseI1'] ?? false,
        json['DefenseI2'] ?? false,
        json['NeutralTrips'] ?? 0,
        json['NeutralTripsA1'] ?? 0,
        json['NeutralTripsA2'] ?? 0,
        json['NeutralTripsI1'] ?? 0,
        json['NeutralTripsI2'] ?? 0,
        json['FeedToHPStation'] ?? false,
        json['FeedToHPStationA1'] ?? false,
        json['FeedToHPStationA2'] ?? false,
        json['FeedToHPStationI1'] ?? false,
        json['FeedToHPStationI2'] ?? false,
        json['passing'] ?? false,
        json['passingA1'] ?? false,
        json['passingA2'] ?? false,
        json['passingI1'] ?? false,
        json['passingI2'] ?? false);
  }

  static EndPoints mapToEndPoints(Map<dynamic, dynamic> data) {
    return EndPoints(
      data['ClimbStatus'] ?? 0,
      data['Park'] ?? false,
      data['FeedToHP'] ?? false,
      data['Passing'] ?? false,
      data['Comments'] ?? "",
      data['EndNeutralTrips'] ?? 0,
      data['ShootingAccuracy'] ?? 3,
      (data['EndgameTime'] ?? 0).toDouble(),
      data['EndgameActions'] ?? 0,
      (data['DrawingData'] is List) ? List<int>.from(data['DrawingData']) : [],
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
        botImage1: data['botImage1'] ?? "",
        botImage2: data['botImage2'] ?? "",
        botImage3: data['botImage3'] ?? "");
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
  bool intake_motors = false;
  bool intake_limit_switches = false;
  bool intake_lime_lights = false;
  bool intake_nuts_and_bolts = false;
  bool intake_wires = false;

  //spindexer
  bool spindexer_panel = false;
  bool spindexer_churros = false;
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
    required this.intake_motors,
    required this.intake_limit_switches,
    required this.intake_lime_lights,
    required this.intake_nuts_and_bolts,
    required this.intake_wires,
    //spindexer
    required this.spindexer_panel,
    required this.spindexer_churros,
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
        '$intake_rack,$intake_pinion,$intake_belts,$intake_roller,$intake_motors,$intake_limit_switches,$intake_lime_lights,$intake_nuts_and_bolts,$intake_wires,'
        //spindexer
        '$spindexer_panel,$spindexer_churros,$spindexer_motor,$spindexer_wheels,$spindexer_nuts_and_bolts'
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
      'intake_motors': intake_motors,
      'intake_limit_switches': intake_limit_switches,
      'intake_lime_lights': intake_lime_lights,
      'intake_nuts_and_bolts': intake_nuts_and_bolts,
      'intake_wires': intake_wires,
      //spindexer
      'spindexer_panel': spindexer_panel,
      'spindexer_churros': spindexer_churros,
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
        intake_motors: json['intake_motors'] ?? false,
        intake_limit_switches: json['intake_limit_switches'] ?? false,
        intake_lime_lights: json['intake_lime_lights'] ?? false,
        intake_nuts_and_bolts: json['intake_nuts_and_bolts'] ?? false,
        intake_wires: json['intake_wires'] ?? false,
        //spindexer
        spindexer_panel: json['spindexer_panel'] ?? false,
        spindexer_churros: json['spindexer_churros'] ?? false,
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
