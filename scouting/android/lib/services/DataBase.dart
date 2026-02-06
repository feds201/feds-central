import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
  // BotLocation starting_location;

  AutonPoints(
    this.fuel_pickup_from_Depot,
    this.fuel_pickup_from_Outpost,
    this.fuel_pickup_from_Neutral_Zone,
    this.total_shooting_time,
    this.amountOfShooting,
    this.climb,
    this.winAfterAuton,
    // this.starting_location,
    this.left_starting_position,
  );

  Map<String, dynamic> toJson() {
    return {
      "FuelPickUpFromDepot": fuel_pickup_from_Depot,
      "FuelPickUpFromOutpost": fuel_pickup_from_Outpost,
      "FuelPickUpFromNeutralZone": fuel_pickup_from_Neutral_Zone,
      "TotalShootingTime": total_shooting_time,
      "Climb": climb,
      "WinAfterAuton": winAfterAuton,
      // "RobotLocation": starting_location,
      "LeftStartingPosition": left_starting_position
    };
  }

  String toCsv() {
    return '{${left_starting_position},${fuel_pickup_from_Depot},${fuel_pickup_from_Outpost},${fuel_pickup_from_Neutral_Zone},${total_shooting_time},${amountOfShooting},${climb},${winAfterAuton}}';
  }

  static AutonPoints fromJson(Map<String, dynamic> json) {
    return AutonPoints(
      json['FuelPickUpFromDepot'] ?? false,
      json['FuelPickUpFromOutpost'] ?? false,
      json['FuelPickUpFromNeutralZone'] ?? false,
      json['TotalShootingTime'] ?? 0,
      json["Amount of Shooting"] ?? 0,
      json['Climb'] ?? false,
      json['WinAfterAuton'] ?? "",
      // BotLocation.fromJson(
      //   json['RobotLocation'] ?? {},
      // ),
      json['LeftStartingPosition'] ?? false,
    );
  }

  @override
  String toString() {
    return 'AutonPoints{FuelPickUpFromDepot: $fuel_pickup_from_Depot, FuelPickUpFromOutpost: $fuel_pickup_from_Outpost, FuelPickUpFromNeutralZone: $fuel_pickup_from_Neutral_Zone, TotalShootingTime: $total_shooting_time, Climb: $climb, WinAfterAuton: $winAfterAuton, LeftStartingPosition: $left_starting_position}';
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

  setClimb(bool value) {
    climb = value;
  }

  setWinAfterAuton(String value) {
    winAfterAuton = value;
  }

  setStartingLocation(BotLocation value) {
    // starting_location = value;
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
  double TotalShootingTime1 = 0;
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
    this.CoralScoringLevel1,
    this.CoralScoringLevel2,
    this.CoralScoringLevel3,
    this.CoralScoringLevel4,
    this.AlgaeScoringBarge,
    this.AlgaeScoringProcessor,
    this.AlgaePickUp,
    this.TotalShootingTime1,
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
      this.passingI2
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
      "TotalShootingTime": TotalShootingTime1,
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
    return '${CoralScoringLevel1},${CoralScoringLevel2},${CoralScoringLevel3},${CoralScoringLevel4},${AlgaeScoringBarge},${AlgaeScoringProcessor},${AlgaePickUp},${TotalShootingTime1},${TotalAmount1}, ${TotalAmountA1}, ${TotalAmountA2}, ${TotalAmountI1}, ${TotalAmountI2}, ${TripAmount1}, ${NeutralTrips}, ${NeutralTripsA1}, ${NeutralTripsA2}, ${NeutralTripsI1}, ${NeutralTripsI2}, ${Defense} ${DefenseA1} ${DefenseA2} ${DefenseI1} ${DefenseI2}, ${FeedToHPStation} ${FeedToHPStationA1} ${FeedToHPStationA2} ${FeedToHPStationI1} ${FeedToHPStationI2}, ${passing} ${passingA1} ${passingA2} ${passingI1} ${passingI2}';
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
      json['TotalShootingTime1'] ?? 0,
      json['TotalAmount1'] ?? 0,
      json['TotalAmountA1'] ?? 0,
      json['TotalAmountA2'] ?? 0,
      json['TotalAmountI1'] ?? 0,
      json['TotalAmountI2'] ?? 0,
      json['TripAmount1'] ?? 0,
      json['NeutralTrips'] ?? 0,
      json['NeutralTripsA1'] ?? 0,
      json['NeutralTripsA2'] ?? 0,
      json['NeutralTripsI1'] ?? 0,
      json['NeutralTripsI2'] ?? 0,
      json['Defense'] ?? 0,
      json['DefenseA1'] ?? 0,
      json['DefenseA2'] ?? 0,
      json['DefenseI1'] ?? 0,
      json['DefenseI2'] ?? 0,
      json['FeedToHPStation'] ?? 0,
      json['FeedToHPStationA1'] ?? 0,
      json['FeedToHPStationA2'] ?? 0,
      json['FeedToHPStationI1'] ?? 0,
      json['FeedToHPStationI2'] ?? 0,
      json['passing'] ?? 0,
      json['passingA1'] ?? 0,
      json['passingA2'] ?? 0,
      json['passingI1'] ?? 0,
      json['passingI2'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'TeleOpPoints{CoralScoringLevel1: $CoralScoringLevel1, CoralScoringLevel2: $CoralScoringLevel2, CoralScoringLevel3: $CoralScoringLevel3, CoralScoringLevel4: $CoralScoringLevel4, AlgaeScoringBarge: $AlgaeScoringBarge, AlgaeScoringProcessor: $AlgaeScoringProcessor, TotalShootingTime1: $TotalShootingTime1, TotalAmount1 $TotalAmount1, TotalAmountA1 $TotalAmountA1, TotalAmountA2 $TotalAmountA2, TotalAmountI1 $TotalAmountI1, TotalAmountI2 $TotalAmountI2, TripAmount1 $TripAmount1, NeutralTips $NeutralTrips, NeutralTipsA1 $NeutralTripsA1, NeutralTipsA2 $NeutralTripsA2, NeutralTipsI1 $NeutralTripsI1, NeutralTipsI2 $NeutralTripsI2, Defense: $Defense DefenseA1: $DefenseA1, DefenseA2: $DefenseA2, DefenseI1: $DefenseI1, DefenseI2: $DefenseI2, FeedToHPStation: $FeedToHPStation FeedToHPStationA1: $FeedToHPStationA1, FeedToHPStationA2: $FeedToHPStationA2 FeedToHPStationI1: $FeedToHPStationI1, FeedToHPStationI2: $FeedToHPStationI2, passing: $passing, passingA1: $passingA1, passingA2: $passingA2, passingI1: $passingI1 passingI2: $passingI2}';
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

  setTotalShootingTime1(double value){
    TotalShootingTime1 = value;
  }

  setTotalAmount1(int value){
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


  setTripAmount1(int value){
    TripAmount1 = value;
  }

  setNeutralTrips(int value){
    NeutralTrips = value;
  }

  setNeutralTripsA1(int value){
    NeutralTripsA1 = value;
  }

  setNeutralTripsA2(int value){
    NeutralTripsA2 = value;
  }

  setNeutralTripsI1(int value){
    NeutralTripsI1 = value;
  }

  setNeutralTripsI2(int value){
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
      data['FuelPickUpFromDepot'] ?? false,
      data['FuelPickUpFromOutpost'] ?? false,
      data['FuelPickUpFromNeutralZone'] ?? false,
      data['TotalShootingTime'] ?? 0,
      data['aMOUNT OF SHOOTING'] ?? 0,
      data['Climb'] ?? false,
      data['WinAfterAuton'] ?? "",
      data['RobotLocation'] ?? Offset.zero,
      // data['LeftStartingPosition'] ?? false,
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
      data['AlgaePickUp'] ?? 0,
      data['TotalShootingTime1'] ?? 0,
      data['TotalAmount1'] ?? 0,
      data['TotalAmountA1'] ?? 0,
      data['TotalAmountA2'] ?? 0,
      data['TotalAmountI1'] ?? 0,
      data['TotalAmountI2'] ?? 0,
      data['TripAmount1'] ?? 0,
      data['NeutralTips'] ?? 0,
      data['NeutralTipsA1'] ?? 0,
      data['NeutralTipsA2'] ?? 0,
      data['NeutralTipsI1'] ?? 0,
      data['NeutralTipsI2'] ?? 0,
      data['Defended'] ?? false,
      data['DefendedA1'] ?? false,
      data['DefendedA2'] ?? false,
      data['DefendedI1'] ?? false,
      data['DefendedI2'] ?? false,
      data['FeedToHPStation'] ?? false,
      data['FeedToHPStationA1'] ?? false,
      data['FeedToHPStationA2'] ?? false,
      data['FeedToHPStationI1'] ?? false,
      data['FeedToHPStationI2'] ?? false,
      data['passing'] ?? false,
      data['passingA1'] ?? false,
      data['passingA2'] ?? false,
      data['passingI1'] ?? false,
      data['passingI2'] ?? false,
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
    return "null";
    // return '${position.dx},${position.dy},${size.width},${size.height},$angle';
  }
}

class PitChecklistItem {
  String note = "";
  String matchkey = "";
  bool chassis_drive_motors = false;
  bool chassis_steer_motors = false;
  bool chassis_gearboxes = false;
  bool chassis_tread_conditions = false;
  bool chassis_wires = false;
  bool chassis_bumpers = false;
  bool chassis_camera = false;
  bool chassis_limelight_protectors = false;

  bool ethernet_front_left_limelight = false;
  bool ethernet_front_right_limelight = false;
  bool ethernet_back_right_limelight = false;
  bool ethernet_switch = false; // Changed from ethernet_swtich
  bool ethernet_radio = false;

  bool climber_bumper = false;
  bool climber_hooks = false;
  bool climber_string = false;
  bool climber_springs = false;
  bool climber_gearbox = false;
  bool climber_motors = false;
  bool climber_wires = false;
  bool climber_nuts_and_bolts = false;
  bool climber_reset = false;
  bool climber_clips = false;

  bool elevator_rod_of_doom = false;
  bool elevator_stage_0 = false;
  bool elevator_stage_1 = false;
  bool elevator_stage_2 = false;
  bool elevator_chain = false;
  bool elevator_gearbox = false;
  bool elevator_limit_switch = false;
  bool elevator_motors = false;
  bool elevator_wires = false;
  bool elevator_nuts_and_bolts = false;
  bool elevator_belts = false;
  bool elevator_string = false;

  bool trapdoor_panels = false;
  bool trapdoor_supports = false;
  bool trapdoor_hinges = false;
  bool trapdoor_tensioners = false;
  bool trapdoor_wires = false;
  bool trapdoor_nuts_and_bolts = false;
  bool trapdoor_reset = false;

  bool carriage_gearbox = false;
  bool carriage_beltbox = false;
  bool carriage_motors = false;
  bool carriage_wires = false;
  bool carriage_nuts_and_bolts = false;
  bool carriage_coral_slide = false;
  bool carriage_reset = false;
  bool carriage_carriage = false;

  bool gooseneck_panels = false;
  bool gooseneck_wheels = false;
  bool gooseneck_belts = false;
  bool gooseneck_nuts_and_bolts = false;
  bool gooseneck_gears = false;
  bool gooseneck_wires = false;

  double returning_battery_voltage = 0.0;
  double returning_battery_cca = 0.0;
  double returning_number = 0.0;
  double outgoing_battery_voltage = 0.0;
  double outgoing_battery_cca = 0.0;
  double outgoing_number = 0.0;
  bool outgoing_battery_replaced = false;
  String alliance_color = "Blue";
  Map<String, dynamic>? alliance_selection_data;
  String img1 = "";
  String img2 = "";
  String img3 = "";
  String img4 = "";
  String img5 = "";

  PitChecklistItem({
    required this.matchkey,
    required this.chassis_drive_motors,
    required this.chassis_steer_motors,
    required this.chassis_gearboxes,
    required this.chassis_tread_conditions,
    required this.chassis_camera,
    required this.chassis_wires,
    required this.chassis_bumpers,
    required this.chassis_limelight_protectors,
    required this.ethernet_front_left_limelight,
    required this.ethernet_front_right_limelight,
    required this.ethernet_back_right_limelight,
    required this.ethernet_switch, // Changed from ethernet_swtich
    required this.ethernet_radio,
    required this.climber_string,
    required this.climber_bumper,
    required this.climber_hooks,
    required this.climber_clips,
    required this.climber_springs,
    required this.climber_gearbox,
    required this.climber_motors,
    required this.climber_wires,
    required this.climber_nuts_and_bolts,
    required this.climber_reset,
    required this.elevator_rod_of_doom,
    required this.elevator_stage_0,
    required this.elevator_stage_1,
    required this.elevator_stage_2,
    required this.elevator_chain,
    required this.elevator_gearbox,
    required this.elevator_motors,
    required this.elevator_limit_switch,
    required this.elevator_wires,
    required this.elevator_nuts_and_bolts,
    required this.elevator_belts,
    required this.elevator_string,
    required this.trapdoor_panels,
    required this.trapdoor_supports,
    required this.trapdoor_hinges,
    required this.trapdoor_tensioners,
    required this.trapdoor_wires,
    required this.trapdoor_nuts_and_bolts,
    required this.trapdoor_reset,
    required this.carriage_gearbox,
    required this.carriage_beltbox,
    required this.carriage_motors,
    required this.carriage_wires,
    required this.carriage_nuts_and_bolts,
    required this.carriage_coral_slide,
    required this.carriage_reset,
    required this.carriage_carriage,
    required this.gooseneck_panels,
    required this.gooseneck_wheels,
    required this.gooseneck_belts,
    required this.gooseneck_nuts_and_bolts,
    required this.gooseneck_gears,
    required this.gooseneck_wires,
    required this.returning_battery_voltage,
    required this.returning_battery_cca,
    required this.returning_number,
    required this.outgoing_battery_voltage,
    required this.outgoing_battery_cca,
    required this.outgoing_number,
    required this.outgoing_battery_replaced,
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
        '$chassis_drive_motors, $chassis_camera, $chassis_steer_motors,$chassis_gearboxes,$chassis_tread_conditions,$chassis_wires,$chassis_bumpers,$chassis_limelight_protectors,'
        '$ethernet_front_left_limelight,$ethernet_front_right_limelight,$ethernet_switch,$ethernet_radio,' // Changed from ethernet_swtich
        '$climber_string,$climber_springs,$climber_gearbox,$climber_motors,$climber_wires,$climber_nuts_and_bolts,$climber_bumper,$climber_reset,$climber_bumper,$climber_clips,'
        '$elevator_rod_of_doom,$elevator_limit_switch,$elevator_belts,$elevator_stage_0,$elevator_stage_1,$elevator_stage_2,$elevator_chain,$elevator_gearbox, $elevator_string,$elevator_motors,$elevator_wires,$elevator_nuts_and_bolts,'
        '$trapdoor_panels,$trapdoor_supports,$trapdoor_hinges,$trapdoor_tensioners,$trapdoor_nuts_and_bolts,$trapdoor_reset,$trapdoor_wires,'
        '$carriage_gearbox,$carriage_beltbox,$carriage_motors,$carriage_wires,$carriage_nuts_and_bolts,$carriage_coral_slide,$carriage_carriage,'
        '$gooseneck_panels,$gooseneck_wheels,$gooseneck_belts,$gooseneck_nuts_and_bolts,'
        '$returning_battery_voltage,$returning_battery_cca,$returning_number,'
        '$outgoing_battery_voltage,$outgoing_battery_cca,$outgoing_number,$outgoing_battery_replaced,'
        '$alliance_color';
  }

  Map<String, dynamic> toJson() {
    return {
      'matchkey': matchkey,
      'chassis_drive_motors': chassis_drive_motors,
      'chassis_steer_motors': chassis_steer_motors,
      'chassis_gearboxes': chassis_gearboxes,
      'chassis_tread_conditions': chassis_tread_conditions,
      'chassis_wires': chassis_wires,
      'chassis_camera': chassis_camera,
      'chassis_bumpers': chassis_bumpers,
      'chassis_limelight_protectors': chassis_limelight_protectors,
      'ethernet_front_left_limelight': ethernet_front_left_limelight,
      'ethernet_front_right_limelight': ethernet_front_right_limelight,
      'ethernet_back_right_limelight': ethernet_back_right_limelight,
      'ethernet_switch': ethernet_switch, // Changed from ethernet_swtich
      'ethernet_radio': ethernet_radio,
      'climber_string': climber_string,
      'climber_clips': climber_clips,
      'climber_springs': climber_springs,
      'climber_hooks': climber_hooks,
      'climber_gearbox': climber_gearbox,
      'climber_motors': climber_motors,
      'climber_wires': climber_wires,
      'climber_nuts_and_bolts': climber_nuts_and_bolts,
      'climber_reset': climber_reset,
      'climber_bumper': climber_bumper,
      'elevator_rod_of_doom': elevator_rod_of_doom,
      'elevator_stage_0': elevator_stage_0,
      'elevator_stage_1': elevator_stage_1,
      'elevator_belts': elevator_belts,
      'elevator_stage_2': elevator_stage_2,
      'elevator_chain': elevator_chain,
      'elevator_gearbox': elevator_gearbox,
      'elevator_motors': elevator_motors,
      'elevator_limit_switch': elevator_limit_switch,
      'elevator_string': elevator_string,
      'elevator_wires': elevator_wires,
      'elevator_nuts_and_bolts': elevator_nuts_and_bolts,
      'trapdoor_panels': trapdoor_panels,
      'trapdoor_wires': trapdoor_wires,
      'trapdoor_supports': trapdoor_supports,
      'trapdoor_hinges': trapdoor_hinges,
      'trapdoor_tensioners': trapdoor_tensioners,
      'trapdoor_nuts_and_bolts': trapdoor_nuts_and_bolts,
      'trapdoor_reset': trapdoor_reset,
      'carriage_gearbox': carriage_gearbox,
      'carriage_beltbox': carriage_beltbox,
      'carriage_motors': carriage_motors,
      'carriage_wires': carriage_wires,
      'carriage_nuts_and_bolts': carriage_nuts_and_bolts,
      'carriage_coral_slide': carriage_coral_slide,
      'carriage_reset': carriage_reset,
      'carriage_carriage': carriage_carriage,
      'gooseneck_panels': gooseneck_panels,
      'gooseneck_wheels': gooseneck_wheels,
      'gooseneck_belts': gooseneck_belts,
      'gooseneck_wires': gooseneck_wires,
      'gooseneck_nuts_and_bolts': gooseneck_nuts_and_bolts,
      'gooseneck_gears': gooseneck_gears,
      'returning_battery_voltage': returning_battery_voltage,
      'returning_battery_cca': returning_battery_cca,
      'returning_number': returning_number,
      'outgoing_battery_voltage': outgoing_battery_voltage,
      'outgoing_battery_cca': outgoing_battery_cca,
      'outgoing_number': outgoing_number,
      'outgoing_battery_replaced': outgoing_battery_replaced,
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
        gooseneck_wires: json['gooseneck_wires'] ?? false,
        chassis_drive_motors: json['chassis_drive_motors'] ?? false,
        chassis_steer_motors: json['chassis_steer_motors'] ?? false,
        chassis_gearboxes: json['chassis_gearboxes'] ?? false,
        chassis_tread_conditions: json['chassis_tread_conditions'] ?? false,
        chassis_wires: json['chassis_wires'] ?? false,
        chassis_camera: json['chassi_camera'] ?? false,
        chassis_bumpers: json['chassis_bumpers'] ?? false,
        chassis_limelight_protectors:
            json['chassis_limelight_protectors'] ?? false,
        ethernet_front_left_limelight:
            json['ethernet_front_left_limelight'] ?? false,
        ethernet_front_right_limelight:
            json['ethernet_front_right_limelight'] ?? false,
        ethernet_back_right_limelight:
            json['ethernet_back_right_limelight'] ?? false,
        ethernet_radio: json['ethernet_radio'] ?? false,
        climber_hooks: json['climber_hooks'] ?? false,
        carriage_reset: json['carriage_reset'] ?? false,
        climber_wires: json['climber_wires'] ?? false,
        climber_clips: json['climber_clips'] ?? false,
        climber_bumper: json['climber_bumper'] ?? false,
        climber_string: json['climber_string'] ?? false,
        climber_springs: json['climber_springs'] ?? false,
        climber_gearbox: json['climber_gearbox'] ?? false,
        climber_motors: json['climber_motors'] ?? false,
        climber_nuts_and_bolts: json['climber_nuts_and_bolts'] ?? false,
        climber_reset: json['climber_reset'] ?? false,
        elevator_rod_of_doom: json['elevator_rod_of_doom'] ?? false,
        elevator_belts: json['elevator_belts'] ?? false,
        elevator_stage_0: json['elevator_stage_0'] ?? false,
        elevator_stage_1: json['elevator_stage_1'] ?? false,
        elevator_stage_2: json['elevator_stage_2'] ?? false,
        elevator_chain: json['elevator_chain'] ?? false,
        elevator_gearbox: json['elevator_gearbox'] ?? false,
        elevator_motors: json['elevator_motors'] ?? false,
        elevator_limit_switch: json['elevator_limit_switch'] ?? false,
        elevator_string: json['elevator_string'] ?? false,
        elevator_wires: json['elevator_wires'] ?? false,
        elevator_nuts_and_bolts: json['elevator_nuts_and_bolts'] ?? false,
        trapdoor_panels: json['trapdoor_panels'] ?? false,
        trapdoor_wires: json['trapdoor_wires'] ?? false,
        trapdoor_supports: json['trapdoor_supports'] ?? false,
        trapdoor_hinges: json['trapdoor_hinges'] ?? false,
        trapdoor_tensioners: json['trapdoor_tensioners'] ?? false,
        trapdoor_nuts_and_bolts: json['trapdoor_nuts_and_bolts'] ?? false,
        trapdoor_reset: json['trapdoor_reset'] ?? false,
        carriage_gearbox: json['carriage_gearbox'] ?? false,
        carriage_beltbox: json['carriage_beltbox'] ?? false,
        carriage_motors: json['carriage_motors'] ?? false,
        carriage_wires: json['carriage_wires'] ?? false,
        carriage_nuts_and_bolts: json['carriage_nuts_and_bolts'] ?? false,
        carriage_coral_slide: json['carriage_coral_slide'] ?? false,
        carriage_carriage: json['carriage_carriage'] ?? false,
        gooseneck_panels: json['gooseneck_panels'] ?? false,
        gooseneck_gears: json['gooseneck_gears'] ?? false,
        gooseneck_wheels: json['gooseneck_wheels'] ?? false,
        gooseneck_belts: json['gooseneck_belts'] ?? false,
        gooseneck_nuts_and_bolts: json['gooseneck_nuts_and_bolts'] ?? false,
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
        img1: json['img1'] ?? "",
        img2: json['img2'] ?? "",
        img3: json['img3'] ?? "",
        img4: json['img4'] ?? "",
        img5: json['img5'] ?? "",
        alliance_color: json['alliance_color'] ?? "",
        alliance_selection_data: json['alliance_selection_data'],
        ethernet_switch: json['ethernet_switch'] ?? false, // Corrected spelling
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
