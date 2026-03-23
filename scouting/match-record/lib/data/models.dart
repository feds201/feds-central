import 'package:match_record/util/constants.dart';

class Event {
  final String eventKey;
  final String name;
  final String shortName;
  final DateTime startDate;
  final DateTime endDate;
  final int playoffType;
  final String timezone;

  const Event({
    required this.eventKey,
    required this.name,
    required this.shortName,
    required this.startDate,
    required this.endDate,
    required this.playoffType,
    required this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'eventKey': eventKey,
        'name': name,
        'shortName': shortName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'playoffType': playoffType,
        'timezone': timezone,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        eventKey: json['eventKey'] as String? ?? '',
        name: json['name'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : DateTime(2000),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : DateTime(2000),
        playoffType: json['playoffType'] as int? ?? 0,
        timezone: json['timezone'] as String? ?? '',
      );

  Event copyWith({
    String? eventKey,
    String? name,
    String? shortName,
    DateTime? startDate,
    DateTime? endDate,
    int? playoffType,
    String? timezone,
  }) =>
      Event(
        eventKey: eventKey ?? this.eventKey,
        name: name ?? this.name,
        shortName: shortName ?? this.shortName,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        playoffType: playoffType ?? this.playoffType,
        timezone: timezone ?? this.timezone,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          eventKey == other.eventKey &&
          name == other.name &&
          shortName == other.shortName &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          playoffType == other.playoffType &&
          timezone == other.timezone;

  @override
  int get hashCode => Object.hash(
        eventKey,
        name,
        shortName,
        startDate,
        endDate,
        playoffType,
        timezone,
      );
}

class Team {
  final String eventKey;
  final int teamNumber;
  final String nickname;

  const Team({
    required this.eventKey,
    required this.teamNumber,
    this.nickname = '',
  });

  Map<String, dynamic> toJson() => {
        'eventKey': eventKey,
        'teamNumber': teamNumber,
        'nickname': nickname,
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        eventKey: json['eventKey'] as String? ?? '',
        teamNumber: json['teamNumber'] as int? ?? 0,
        nickname: json['nickname'] as String? ?? '',
      );

  Team copyWith({
    String? eventKey,
    int? teamNumber,
    String? nickname,
  }) =>
      Team(
        eventKey: eventKey ?? this.eventKey,
        teamNumber: teamNumber ?? this.teamNumber,
        nickname: nickname ?? this.nickname,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          eventKey == other.eventKey &&
          teamNumber == other.teamNumber &&
          nickname == other.nickname;

  @override
  int get hashCode => Object.hash(eventKey, teamNumber, nickname);
}

class Match {
  final String matchKey;
  final String eventKey;
  final String compLevel;
  final int setNumber;
  final int matchNumber;
  final int? time;
  final int? actualTime;
  final int? predictedTime;
  final List<String> redTeamKeys;
  final List<String> blueTeamKeys;
  final int redScore;
  final int blueScore;
  final String winningAlliance;
  final String? youtubeKey;

  const Match({
    required this.matchKey,
    required this.eventKey,
    required this.compLevel,
    required this.setNumber,
    required this.matchNumber,
    this.time,
    this.actualTime,
    this.predictedTime,
    required this.redTeamKeys,
    required this.blueTeamKeys,
    this.redScore = -1,
    this.blueScore = -1,
    this.winningAlliance = '',
    this.youtubeKey,
  });

  int? get bestTime => actualTime ?? predictedTime ?? time;

  String get displayName {
    switch (compLevel) {
      case 'qm':
        return 'Q$matchNumber';
      case 'sf':
        return 'SF $setNumber';
      case 'f':
        return 'F$matchNumber';
      case 'ef':
        return 'EF $matchNumber';
      case 'qf':
        return 'QF $setNumber-$matchNumber';
      default:
        return matchKey;
    }
  }

  int get compLevelPriority {
    switch (compLevel) {
      case 'qm':
        return 0;
      case 'ef':
        return 1;
      case 'qf':
        return 2;
      case 'sf':
        return 3;
      case 'f':
        return 4;
      default:
        return 5;
    }
  }

  Map<String, dynamic> toJson() => {
        'matchKey': matchKey,
        'eventKey': eventKey,
        'compLevel': compLevel,
        'setNumber': setNumber,
        'matchNumber': matchNumber,
        'time': time,
        'actualTime': actualTime,
        'predictedTime': predictedTime,
        'redTeamKeys': redTeamKeys,
        'blueTeamKeys': blueTeamKeys,
        'redScore': redScore,
        'blueScore': blueScore,
        'winningAlliance': winningAlliance,
        'youtubeKey': youtubeKey,
      };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        matchKey: json['matchKey'] as String? ?? '',
        eventKey: json['eventKey'] as String? ?? '',
        compLevel: json['compLevel'] as String? ?? 'qm',
        setNumber: json['setNumber'] as int? ?? 1,
        matchNumber: json['matchNumber'] as int? ?? 0,
        time: json['time'] as int?,
        actualTime: json['actualTime'] as int?,
        predictedTime: json['predictedTime'] as int?,
        redTeamKeys: (json['redTeamKeys'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        blueTeamKeys: (json['blueTeamKeys'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        redScore: json['redScore'] as int? ?? -1,
        blueScore: json['blueScore'] as int? ?? -1,
        winningAlliance: json['winningAlliance'] as String? ?? '',
        youtubeKey: json['youtubeKey'] as String?,
      );

  Match copyWith({
    String? matchKey,
    String? eventKey,
    String? compLevel,
    int? setNumber,
    int? matchNumber,
    int? Function()? time,
    int? Function()? actualTime,
    int? Function()? predictedTime,
    List<String>? redTeamKeys,
    List<String>? blueTeamKeys,
    int? redScore,
    int? blueScore,
    String? winningAlliance,
    String? Function()? youtubeKey,
  }) =>
      Match(
        matchKey: matchKey ?? this.matchKey,
        eventKey: eventKey ?? this.eventKey,
        compLevel: compLevel ?? this.compLevel,
        setNumber: setNumber ?? this.setNumber,
        matchNumber: matchNumber ?? this.matchNumber,
        time: time != null ? time() : this.time,
        actualTime: actualTime != null ? actualTime() : this.actualTime,
        predictedTime:
            predictedTime != null ? predictedTime() : this.predictedTime,
        redTeamKeys: redTeamKeys ?? this.redTeamKeys,
        blueTeamKeys: blueTeamKeys ?? this.blueTeamKeys,
        redScore: redScore ?? this.redScore,
        blueScore: blueScore ?? this.blueScore,
        winningAlliance: winningAlliance ?? this.winningAlliance,
        youtubeKey: youtubeKey != null ? youtubeKey() : this.youtubeKey,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          runtimeType == other.runtimeType &&
          matchKey == other.matchKey &&
          eventKey == other.eventKey &&
          compLevel == other.compLevel &&
          setNumber == other.setNumber &&
          matchNumber == other.matchNumber &&
          time == other.time &&
          actualTime == other.actualTime &&
          predictedTime == other.predictedTime &&
          _listEquals(redTeamKeys, other.redTeamKeys) &&
          _listEquals(blueTeamKeys, other.blueTeamKeys) &&
          redScore == other.redScore &&
          blueScore == other.blueScore &&
          winningAlliance == other.winningAlliance &&
          youtubeKey == other.youtubeKey;

  @override
  int get hashCode => Object.hash(
        matchKey,
        eventKey,
        compLevel,
        setNumber,
        matchNumber,
        time,
        actualTime,
        predictedTime,
        Object.hashAll(redTeamKeys),
        Object.hashAll(blueTeamKeys),
        redScore,
        blueScore,
        winningAlliance,
        youtubeKey,
      );
}

class Alliance {
  final String eventKey;
  final int allianceNumber;
  final String name;
  final List<String> picks;

  const Alliance({
    required this.eventKey,
    required this.allianceNumber,
    required this.name,
    required this.picks,
  });

  Map<String, dynamic> toJson() => {
        'eventKey': eventKey,
        'allianceNumber': allianceNumber,
        'name': name,
        'picks': picks,
      };

  factory Alliance.fromJson(Map<String, dynamic> json) => Alliance(
        eventKey: json['eventKey'] as String? ?? '',
        allianceNumber: json['allianceNumber'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        picks: (json['picks'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Alliance copyWith({
    String? eventKey,
    int? allianceNumber,
    String? name,
    List<String>? picks,
  }) =>
      Alliance(
        eventKey: eventKey ?? this.eventKey,
        allianceNumber: allianceNumber ?? this.allianceNumber,
        name: name ?? this.name,
        picks: picks ?? this.picks,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alliance &&
          runtimeType == other.runtimeType &&
          eventKey == other.eventKey &&
          allianceNumber == other.allianceNumber &&
          name == other.name &&
          _listEquals(picks, other.picks);

  @override
  int get hashCode =>
      Object.hash(eventKey, allianceNumber, name, Object.hashAll(picks));
}

class Recording {
  final String id;
  final String eventKey;
  final String matchKey;
  final String allianceSide;
  final String fileExtension;
  final DateTime recordingStartTime;
  final int durationMs;
  final int fileSizeBytes;
  final String sourceDeviceType;
  final String originalFilename;
  final int team1;
  final int team2;
  final int team3;

  const Recording({
    required this.id,
    required this.eventKey,
    required this.matchKey,
    required this.allianceSide,
    required this.fileExtension,
    required this.recordingStartTime,
    required this.durationMs,
    required this.fileSizeBytes,
    required this.sourceDeviceType,
    required this.originalFilename,
    required this.team1,
    required this.team2,
    required this.team3,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventKey': eventKey,
        'matchKey': matchKey,
        'allianceSide': allianceSide,
        'fileExtension': fileExtension,
        'recordingStartTime': recordingStartTime.toIso8601String(),
        'durationMs': durationMs,
        'fileSizeBytes': fileSizeBytes,
        'sourceDeviceType': sourceDeviceType,
        'originalFilename': originalFilename,
        'team1': team1,
        'team2': team2,
        'team3': team3,
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'] as String? ?? '',
        eventKey: json['eventKey'] as String? ?? '',
        matchKey: json['matchKey'] as String? ?? '',
        allianceSide: json['allianceSide'] as String? ?? '',
        fileExtension: json['fileExtension'] as String? ?? '.mp4',
        recordingStartTime: json['recordingStartTime'] != null
            ? DateTime.parse(json['recordingStartTime'] as String)
            : DateTime(2000),
        durationMs: json['durationMs'] as int? ?? 0,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        sourceDeviceType: json['sourceDeviceType'] as String? ?? '',
        originalFilename: json['originalFilename'] as String? ?? '',
        team1: json['team1'] as int? ?? 0,
        team2: json['team2'] as int? ?? 0,
        team3: json['team3'] as int? ?? 0,
      );

  Recording copyWith({
    String? id,
    String? eventKey,
    String? matchKey,
    String? allianceSide,
    String? fileExtension,
    DateTime? recordingStartTime,
    int? durationMs,
    int? fileSizeBytes,
    String? sourceDeviceType,
    String? originalFilename,
    int? team1,
    int? team2,
    int? team3,
  }) =>
      Recording(
        id: id ?? this.id,
        eventKey: eventKey ?? this.eventKey,
        matchKey: matchKey ?? this.matchKey,
        allianceSide: allianceSide ?? this.allianceSide,
        fileExtension: fileExtension ?? this.fileExtension,
        recordingStartTime: recordingStartTime ?? this.recordingStartTime,
        durationMs: durationMs ?? this.durationMs,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        sourceDeviceType: sourceDeviceType ?? this.sourceDeviceType,
        originalFilename: originalFilename ?? this.originalFilename,
        team1: team1 ?? this.team1,
        team2: team2 ?? this.team2,
        team3: team3 ?? this.team3,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recording &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventKey == other.eventKey &&
          matchKey == other.matchKey &&
          allianceSide == other.allianceSide &&
          fileExtension == other.fileExtension &&
          recordingStartTime == other.recordingStartTime &&
          durationMs == other.durationMs &&
          fileSizeBytes == other.fileSizeBytes &&
          sourceDeviceType == other.sourceDeviceType &&
          originalFilename == other.originalFilename &&
          team1 == other.team1 &&
          team2 == other.team2 &&
          team3 == other.team3;

  @override
  int get hashCode => Object.hash(
        id,
        eventKey,
        matchKey,
        allianceSide,
        fileExtension,
        recordingStartTime,
        durationMs,
        fileSizeBytes,
        sourceDeviceType,
        originalFilename,
        team1,
        team2,
        team3,
      );
}

class LocalRippedVideo {
  final String matchKey;
  final String filePath;

  const LocalRippedVideo({
    required this.matchKey,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'matchKey': matchKey,
        'filePath': filePath,
      };

  factory LocalRippedVideo.fromJson(Map<String, dynamic> json) =>
      LocalRippedVideo(
        matchKey: json['matchKey'] as String? ?? '',
        filePath: json['filePath'] as String? ?? '',
      );

  LocalRippedVideo copyWith({
    String? matchKey,
    String? filePath,
  }) =>
      LocalRippedVideo(
        matchKey: matchKey ?? this.matchKey,
        filePath: filePath ?? this.filePath,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalRippedVideo &&
          runtimeType == other.runtimeType &&
          matchKey == other.matchKey &&
          filePath == other.filePath;

  @override
  int get hashCode => Object.hash(matchKey, filePath);
}

class ImportSession {
  final String id;
  final DateTime importedAt;
  final String driveLabel;
  final String driveUri;
  final int videoCount;
  final List<ImportSessionEntry> entries;

  const ImportSession({
    required this.id,
    required this.importedAt,
    required this.driveLabel,
    required this.driveUri,
    required this.videoCount,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'importedAt': importedAt.toIso8601String(),
        'driveLabel': driveLabel,
        'driveUri': driveUri,
        'videoCount': videoCount,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory ImportSession.fromJson(Map<String, dynamic> json) => ImportSession(
        id: json['id'] as String? ?? '',
        importedAt: json['importedAt'] != null
            ? DateTime.parse(json['importedAt'] as String)
            : DateTime(2000),
        driveLabel: json['driveLabel'] as String? ?? '',
        driveUri: json['driveUri'] as String? ?? '',
        videoCount: json['videoCount'] as int? ?? 0,
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) =>
                    ImportSessionEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  ImportSession copyWith({
    String? id,
    DateTime? importedAt,
    String? driveLabel,
    String? driveUri,
    int? videoCount,
    List<ImportSessionEntry>? entries,
  }) =>
      ImportSession(
        id: id ?? this.id,
        importedAt: importedAt ?? this.importedAt,
        driveLabel: driveLabel ?? this.driveLabel,
        driveUri: driveUri ?? this.driveUri,
        videoCount: videoCount ?? this.videoCount,
        entries: entries ?? this.entries,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportSession &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          importedAt == other.importedAt &&
          driveLabel == other.driveLabel &&
          driveUri == other.driveUri &&
          videoCount == other.videoCount &&
          _listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(
        id,
        importedAt,
        driveLabel,
        driveUri,
        videoCount,
        Object.hashAll(entries),
      );
}

class ImportSessionEntry {
  final String? recordingId;
  final String originalFilename;
  final bool wasSelected;
  final bool wasAutoSkipped;
  final String? skipReason;
  final DateTime? recordingStartTime;
  final int? durationMs;
  final int? fileSizeBytes;

  const ImportSessionEntry({
    this.recordingId,
    required this.originalFilename,
    required this.wasSelected,
    required this.wasAutoSkipped,
    this.skipReason,
    this.recordingStartTime,
    this.durationMs,
    this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'recordingId': recordingId,
        'originalFilename': originalFilename,
        'wasSelected': wasSelected,
        'wasAutoSkipped': wasAutoSkipped,
        'skipReason': skipReason,
        'recordingStartTime': recordingStartTime?.toIso8601String(),
        'durationMs': durationMs,
        'fileSizeBytes': fileSizeBytes,
      };

  factory ImportSessionEntry.fromJson(Map<String, dynamic> json) =>
      ImportSessionEntry(
        recordingId: json['recordingId'] as String?,
        originalFilename: json['originalFilename'] as String? ?? '',
        wasSelected: json['wasSelected'] as bool? ?? false,
        wasAutoSkipped: json['wasAutoSkipped'] as bool? ?? false,
        skipReason: json['skipReason'] as String?,
        recordingStartTime: json['recordingStartTime'] != null
            ? DateTime.parse(json['recordingStartTime'] as String)
            : null,
        durationMs: json['durationMs'] as int?,
        fileSizeBytes: json['fileSizeBytes'] as int?,
      );

  ImportSessionEntry copyWith({
    String? Function()? recordingId,
    String? originalFilename,
    bool? wasSelected,
    bool? wasAutoSkipped,
    String? Function()? skipReason,
    DateTime? Function()? recordingStartTime,
    int? Function()? durationMs,
    int? Function()? fileSizeBytes,
  }) =>
      ImportSessionEntry(
        recordingId:
            recordingId != null ? recordingId() : this.recordingId,
        originalFilename: originalFilename ?? this.originalFilename,
        wasSelected: wasSelected ?? this.wasSelected,
        wasAutoSkipped: wasAutoSkipped ?? this.wasAutoSkipped,
        skipReason: skipReason != null ? skipReason() : this.skipReason,
        recordingStartTime: recordingStartTime != null
            ? recordingStartTime()
            : this.recordingStartTime,
        durationMs: durationMs != null ? durationMs() : this.durationMs,
        fileSizeBytes:
            fileSizeBytes != null ? fileSizeBytes() : this.fileSizeBytes,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportSessionEntry &&
          runtimeType == other.runtimeType &&
          recordingId == other.recordingId &&
          originalFilename == other.originalFilename &&
          wasSelected == other.wasSelected &&
          wasAutoSkipped == other.wasAutoSkipped &&
          skipReason == other.skipReason &&
          recordingStartTime == other.recordingStartTime &&
          durationMs == other.durationMs &&
          fileSizeBytes == other.fileSizeBytes;

  @override
  int get hashCode => Object.hash(
        recordingId,
        originalFilename,
        wasSelected,
        wasAutoSkipped,
        skipReason,
        recordingStartTime,
        durationMs,
        fileSizeBytes,
      );
}

class VideoSkipEntry {
  final DateTime recordingStartTime;
  final int durationMs;
  final int fileSizeBytes;
  final String? skipReason;

  const VideoSkipEntry({
    required this.recordingStartTime,
    required this.durationMs,
    required this.fileSizeBytes,
    this.skipReason,
  });

  Map<String, dynamic> toJson() => {
        'recordingStartTime': recordingStartTime.toIso8601String(),
        'durationMs': durationMs,
        'fileSizeBytes': fileSizeBytes,
        'skipReason': skipReason,
      };

  factory VideoSkipEntry.fromJson(Map<String, dynamic> json) => VideoSkipEntry(
        recordingStartTime: json['recordingStartTime'] != null
            ? DateTime.parse(json['recordingStartTime'] as String)
            : DateTime(2000),
        durationMs: json['durationMs'] as int? ?? 0,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        skipReason: json['skipReason'] as String?,
      );

  VideoSkipEntry copyWith({
    DateTime? recordingStartTime,
    int? durationMs,
    int? fileSizeBytes,
    String? Function()? skipReason,
  }) =>
      VideoSkipEntry(
        recordingStartTime: recordingStartTime ?? this.recordingStartTime,
        durationMs: durationMs ?? this.durationMs,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        skipReason: skipReason != null ? skipReason() : this.skipReason,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoSkipEntry &&
          runtimeType == other.runtimeType &&
          recordingStartTime == other.recordingStartTime &&
          durationMs == other.durationMs &&
          fileSizeBytes == other.fileSizeBytes &&
          skipReason == other.skipReason;

  @override
  int get hashCode =>
      Object.hash(recordingStartTime, durationMs, fileSizeBytes, skipReason);
}

class VideoIdentity {
  final DateTime recordingStartTime;
  final int durationMs;
  final int fileSizeBytes;

  const VideoIdentity({
    required this.recordingStartTime,
    required this.durationMs,
    required this.fileSizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoIdentity &&
          runtimeType == other.runtimeType &&
          recordingStartTime == other.recordingStartTime &&
          durationMs == other.durationMs &&
          fileSizeBytes == other.fileSizeBytes;

  @override
  int get hashCode =>
      Object.hash(recordingStartTime, durationMs, fileSizeBytes);
}

class AppSettings {
  final int? teamNumber;
  final List<String> selectedEventKeys;
  final int shortVideoThresholdMs;
  final int sequentialGapMinMinutes;
  final int sequentialGapMaxMinutes;
  final double scrubExponent;
  final int scrubMaxRangeMs;
  final bool recordedMatchesOnly;
  final DateTime? lastTbaFetchTime;

  const AppSettings({
    this.teamNumber,
    this.selectedEventKeys = const [],
    this.shortVideoThresholdMs = AppConstants.defaultShortVideoThresholdMs,
    this.sequentialGapMinMinutes = AppConstants.defaultSequentialGapMinMinutes,
    this.sequentialGapMaxMinutes = AppConstants.defaultSequentialGapMaxMinutes,
    this.scrubExponent = AppConstants.defaultScrubExponent,
    this.scrubMaxRangeMs = AppConstants.defaultScrubMaxRangeMs,
    this.recordedMatchesOnly = false,
    this.lastTbaFetchTime,
  });

  Map<String, dynamic> toJson() => {
        'teamNumber': teamNumber,
        'selectedEventKeys': selectedEventKeys,
        'shortVideoThresholdMs': shortVideoThresholdMs,
        'sequentialGapMinMinutes': sequentialGapMinMinutes,
        'sequentialGapMaxMinutes': sequentialGapMaxMinutes,
        'scrubExponent': scrubExponent,
        'scrubMaxRangeMs': scrubMaxRangeMs,
        'recordedMatchesOnly': recordedMatchesOnly,
        'lastTbaFetchTime': lastTbaFetchTime?.toIso8601String(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        teamNumber: json['teamNumber'] as int?,
        selectedEventKeys: (json['selectedEventKeys'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        shortVideoThresholdMs: json['shortVideoThresholdMs'] as int? ??
            AppConstants.defaultShortVideoThresholdMs,
        sequentialGapMinMinutes: json['sequentialGapMinMinutes'] as int? ??
            AppConstants.defaultSequentialGapMinMinutes,
        sequentialGapMaxMinutes: json['sequentialGapMaxMinutes'] as int? ??
            AppConstants.defaultSequentialGapMaxMinutes,
        scrubExponent: (json['scrubExponent'] as num?)?.toDouble() ??
            AppConstants.defaultScrubExponent,
        scrubMaxRangeMs: json['scrubMaxRangeMs'] as int? ??
            AppConstants.defaultScrubMaxRangeMs,
        recordedMatchesOnly: json['recordedMatchesOnly'] as bool? ?? false,
        lastTbaFetchTime: json['lastTbaFetchTime'] != null
            ? DateTime.parse(json['lastTbaFetchTime'] as String)
            : null,
      );

  AppSettings copyWith({
    int? Function()? teamNumber,
    List<String>? selectedEventKeys,
    int? shortVideoThresholdMs,
    int? sequentialGapMinMinutes,
    int? sequentialGapMaxMinutes,
    double? scrubExponent,
    int? scrubMaxRangeMs,
    bool? recordedMatchesOnly,
    DateTime? Function()? lastTbaFetchTime,
  }) =>
      AppSettings(
        teamNumber: teamNumber != null ? teamNumber() : this.teamNumber,
        selectedEventKeys: selectedEventKeys ?? this.selectedEventKeys,
        shortVideoThresholdMs:
            shortVideoThresholdMs ?? this.shortVideoThresholdMs,
        sequentialGapMinMinutes:
            sequentialGapMinMinutes ?? this.sequentialGapMinMinutes,
        sequentialGapMaxMinutes:
            sequentialGapMaxMinutes ?? this.sequentialGapMaxMinutes,
        scrubExponent: scrubExponent ?? this.scrubExponent,
        scrubMaxRangeMs: scrubMaxRangeMs ?? this.scrubMaxRangeMs,
        recordedMatchesOnly:
            recordedMatchesOnly ?? this.recordedMatchesOnly,
        lastTbaFetchTime: lastTbaFetchTime != null
            ? lastTbaFetchTime()
            : this.lastTbaFetchTime,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          teamNumber == other.teamNumber &&
          _listEquals(selectedEventKeys, other.selectedEventKeys) &&
          shortVideoThresholdMs == other.shortVideoThresholdMs &&
          sequentialGapMinMinutes == other.sequentialGapMinMinutes &&
          sequentialGapMaxMinutes == other.sequentialGapMaxMinutes &&
          scrubExponent == other.scrubExponent &&
          scrubMaxRangeMs == other.scrubMaxRangeMs &&
          recordedMatchesOnly == other.recordedMatchesOnly &&
          lastTbaFetchTime == other.lastTbaFetchTime;

  @override
  int get hashCode => Object.hash(
        teamNumber,
        Object.hashAll(selectedEventKeys),
        shortVideoThresholdMs,
        sequentialGapMinMinutes,
        sequentialGapMaxMinutes,
        scrubExponent,
        scrubMaxRangeMs,
        recordedMatchesOnly,
        lastTbaFetchTime,
      );
}

class AppData {
  static const int currentVersion = 1;

  final int version;
  final List<Event> events;
  final List<Team> teams;
  final List<Match> matches;
  final List<Alliance> alliances;
  final List<Recording> recordings;
  final List<LocalRippedVideo> localRippedVideos;
  final List<ImportSession> importSessions;
  final List<VideoSkipEntry> skipHistory;
  final AppSettings settings;

  const AppData({
    required this.version,
    required this.events,
    required this.teams,
    required this.matches,
    required this.alliances,
    required this.recordings,
    required this.localRippedVideos,
    required this.importSessions,
    required this.skipHistory,
    required this.settings,
  });

  factory AppData.empty() => const AppData(
        version: currentVersion,
        events: [],
        teams: [],
        matches: [],
        alliances: [],
        recordings: [],
        localRippedVideos: [],
        importSessions: [],
        skipHistory: [],
        settings: AppSettings(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'events': events.map((e) => e.toJson()).toList(),
        'teams': teams.map((e) => e.toJson()).toList(),
        'matches': matches.map((e) => e.toJson()).toList(),
        'alliances': alliances.map((e) => e.toJson()).toList(),
        'recordings': recordings.map((e) => e.toJson()).toList(),
        'localRippedVideos': localRippedVideos.map((e) => e.toJson()).toList(),
        'importSessions': importSessions.map((e) => e.toJson()).toList(),
        'skipHistory': skipHistory.map((e) => e.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory AppData.fromJson(Map<String, dynamic> json) => AppData(
        version: json['version'] as int? ?? currentVersion,
        events: (json['events'] as List<dynamic>?)
                ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        teams: (json['teams'] as List<dynamic>?)
                ?.map((e) => Team.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        matches: (json['matches'] as List<dynamic>?)
                ?.map((e) => Match.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        alliances: (json['alliances'] as List<dynamic>?)
                ?.map((e) => Alliance.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recordings: (json['recordings'] as List<dynamic>?)
                ?.map((e) => Recording.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        localRippedVideos: (json['localRippedVideos'] as List<dynamic>?)
                ?.map(
                    (e) => LocalRippedVideo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        importSessions: (json['importSessions'] as List<dynamic>?)
                ?.map(
                    (e) => ImportSession.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        skipHistory: (json['skipHistory'] as List<dynamic>?)
                ?.map(
                    (e) => VideoSkipEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        settings: json['settings'] != null
            ? AppSettings.fromJson(json['settings'] as Map<String, dynamic>)
            : const AppSettings(),
      );

  AppData copyWith({
    int? version,
    List<Event>? events,
    List<Team>? teams,
    List<Match>? matches,
    List<Alliance>? alliances,
    List<Recording>? recordings,
    List<LocalRippedVideo>? localRippedVideos,
    List<ImportSession>? importSessions,
    List<VideoSkipEntry>? skipHistory,
    AppSettings? settings,
  }) =>
      AppData(
        version: version ?? this.version,
        events: events ?? this.events,
        teams: teams ?? this.teams,
        matches: matches ?? this.matches,
        alliances: alliances ?? this.alliances,
        recordings: recordings ?? this.recordings,
        localRippedVideos: localRippedVideos ?? this.localRippedVideos,
        importSessions: importSessions ?? this.importSessions,
        skipHistory: skipHistory ?? this.skipHistory,
        settings: settings ?? this.settings,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppData &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          _listEquals(events, other.events) &&
          _listEquals(teams, other.teams) &&
          _listEquals(matches, other.matches) &&
          _listEquals(alliances, other.alliances) &&
          _listEquals(recordings, other.recordings) &&
          _listEquals(localRippedVideos, other.localRippedVideos) &&
          _listEquals(importSessions, other.importSessions) &&
          _listEquals(skipHistory, other.skipHistory) &&
          settings == other.settings;

  @override
  int get hashCode => Object.hash(
        version,
        Object.hashAll(events),
        Object.hashAll(teams),
        Object.hashAll(matches),
        Object.hashAll(alliances),
        Object.hashAll(recordings),
        Object.hashAll(localRippedVideos),
        Object.hashAll(importSessions),
        Object.hashAll(skipHistory),
        settings,
      );
}

class MatchWithVideos {
  final Match match;
  final Recording? redRecording;
  final Recording? blueRecording;
  final LocalRippedVideo? localRippedVideo;
  final String? eventShortName;

  const MatchWithVideos({
    required this.match,
    this.redRecording,
    this.blueRecording,
    this.localRippedVideo,
    this.eventShortName,
  });

  bool get hasRecordings => redRecording != null || blueRecording != null;
  bool get hasYouTube => match.youtubeKey != null;
  bool get hasLocalRippedVideo => localRippedVideo != null;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
