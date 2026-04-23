import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/import/match_suggester.dart';
import 'package:match_record/import/video_metadata_service.dart' show VideoMetadata;

void main() {
  // Helper to create a Match at a specific Unix timestamp
  Match makeMatch({
    required String key,
    required int timeUnixSeconds,
    String eventKey = '2026mimid',
    String compLevel = 'qm',
    int matchNumber = 1,
  }) {
    return Match(
      matchKey: key,
      eventKey: eventKey,
      compLevel: compLevel,
      setNumber: 1,
      matchNumber: matchNumber,
      time: timeUnixSeconds,
      redTeamKeys: const ['frc201', 'frc100', 'frc300'],
      blueTeamKeys: const ['frc400', 'frc500', 'frc600'],
    );
  }

  // Helper to create a VideoMetadata with a specific recording start time
  VideoMetadata makeVideo({
    required DateTime recordingStartTime,
    int durationMs = 60000,
    bool isIOS = true,
  }) {
    return VideoMetadata(
      sourceUri: 'test://file',
      originalFilename: isIOS ? 'test.MOV' : 'test.mp4',
      durationMs: durationMs,
      // For iOS, date == recordingStartTime (creation_time = start)
      // For Android, date == end time, so recordingStartTime = date - duration
      date: isIOS
          ? recordingStartTime
          : recordingStartTime.add(Duration(milliseconds: durationMs)),
      ftypBrand: isIOS ? 'qt  ' : 'isom',
      fileSize: 1000000,
    );
  }

  // Base time: 2026-03-22 14:00:00 UTC (Unix seconds)
  final baseTime = DateTime.utc(2026, 3, 22, 14, 0, 0);
  final baseUnix = baseTime.millisecondsSinceEpoch ~/ 1000;

  group('MatchSuggester.suggest', () {
    test('single video maps to nearest match', () {
      final videos = [makeVideo(recordingStartTime: baseTime)];
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix - 300), // 5 min before
        makeMatch(key: 'qm2', timeUnixSeconds: baseUnix + 60), // 1 min after
        makeMatch(key: 'qm3', timeUnixSeconds: baseUnix + 600), // 10 min after
      ];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: schedule,
        gapMinMinutes: 10,
        gapMaxMinutes: 20,

      );

      expect(results.length, 1);
      expect(results[0].matchKey, 'qm2'); // nearest: 1 min away
      expect(results[0].confidence, MatchSuggestionConfidence.high);
    });

    test('two videos close together (< gapMin) use sequential matching', () {
      // Two videos 5 minutes apart (< 10 min threshold)
      final videos = [
        makeVideo(recordingStartTime: baseTime),
        makeVideo(
          recordingStartTime: baseTime.add(const Duration(minutes: 5)),
        ),
      ];
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
        makeMatch(key: 'qm2', timeUnixSeconds: baseUnix + 900), // 15 min later
        makeMatch(key: 'qm3', timeUnixSeconds: baseUnix + 1800), // 30 min later
      ];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: schedule,
        gapMinMinutes: 10,
        gapMaxMinutes: 20,

      );

      expect(results.length, 2);
      expect(results[0].matchKey, 'qm1');
      // Second video: gap < 10 min, so next sequential match after qm1 = qm2
      expect(results[1].matchKey, 'qm2');
      expect(results[1].confidence, MatchSuggestionConfidence.high);
    });

    test('two videos far apart (> gapMax) both use nearest match', () {
      // Two videos 25 minutes apart (> 20 min threshold)
      final videos = [
        makeVideo(recordingStartTime: baseTime),
        makeVideo(
          recordingStartTime: baseTime.add(const Duration(minutes: 25)),
        ),
      ];
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
        makeMatch(
            key: 'qm5',
            timeUnixSeconds: baseUnix + 1500), // 25 min later, near video 2
      ];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: schedule,
        gapMinMinutes: 10,
        gapMaxMinutes: 20,

      );

      expect(results.length, 2);
      expect(results[0].matchKey, 'qm1');
      expect(results[1].matchKey, 'qm5'); // nearest to video 2's start time
      expect(results[1].confidence, MatchSuggestionConfidence.high);
    });

    test('ambiguous gap (between min and max) returns requiresManual', () {
      // Two videos 15 minutes apart (between 10 and 20 min)
      final videos = [
        makeVideo(recordingStartTime: baseTime),
        makeVideo(
          recordingStartTime: baseTime.add(const Duration(minutes: 15)),
        ),
      ];
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
        makeMatch(key: 'qm2', timeUnixSeconds: baseUnix + 900),
      ];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: schedule,
        gapMinMinutes: 10,
        gapMaxMinutes: 20,

      );

      expect(results.length, 2);
      expect(results[0].matchKey, 'qm1');
      expect(results[1].confidence, MatchSuggestionConfidence.requiresManual);
    });

    test('null recording start time returns none confidence', () {
      final videos = [
        VideoMetadata(
          sourceUri: 'test://file',
          originalFilename: 'broken.mp4',
          durationMs: null,
          date: null,
          ftypBrand: 'isom',
          fileSize: 1000,
        ),
      ];
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
      ];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: schedule,
        gapMinMinutes: 10,
        gapMaxMinutes: 20,

      );

      expect(results.length, 1);
      expect(results[0].confidence, MatchSuggestionConfidence.none);
      expect(results[0].matchKey, isNull);
    });

    test('empty schedule returns none confidence for all videos', () {
      final videos = [makeVideo(recordingStartTime: baseTime)];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: [],
        gapMinMinutes: 10,
        gapMaxMinutes: 20,
      );

      expect(results.length, 1);
      expect(results[0].confidence, MatchSuggestionConfidence.none);
    });

    test('beyond end of schedule returns none confidence', () {
      // Two videos close together, but only 1 match in schedule
      final videos = [
        makeVideo(recordingStartTime: baseTime),
        makeVideo(
          recordingStartTime: baseTime.add(const Duration(minutes: 5)),
        ),
      ];
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
        // No qm2 in schedule
      ];

      final results = MatchSuggester.suggest(
        videos: videos,
        schedule: schedule,
        gapMinMinutes: 10,
        gapMaxMinutes: 20,

      );

      expect(results.length, 2);
      expect(results[0].matchKey, 'qm1');
      // Second video: gap < 10 min, try sequential, but no next match
      expect(results[1].confidence, MatchSuggestionConfidence.none);
    });

    test('empty videos list returns empty results', () {
      final results = MatchSuggester.suggest(
        videos: [],
        schedule: [makeMatch(key: 'qm1', timeUnixSeconds: baseUnix)],
        gapMinMinutes: 10,
        gapMaxMinutes: 20,
      );

      expect(results, isEmpty);
    });

    test('Android video recordingStartTime subtracts duration (no finalization offset)', () {
      final androidVideo = makeVideo(
        recordingStartTime: baseTime,
        durationMs: 60000,
        isIOS: false,
      );
      // Android: date = end time = baseTime + 60s
      // recordingStartTime = date - duration = baseTime
      expect(androidVideo.recordingStartTime, baseTime);
    });

    test('iOS video recordingStartTime equals date directly', () {
      final iosVideo = makeVideo(
        recordingStartTime: baseTime,
        durationMs: 60000,
        isIOS: true,
      );
      expect(iosVideo.recordingStartTime, baseTime);
    });
  });

  group('MatchSuggester.cascadeMatchChange', () {
    test('cascade updates subsequent rows sequentially', () {
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
        makeMatch(key: 'qm2', timeUnixSeconds: baseUnix + 900),
        makeMatch(key: 'qm3', timeUnixSeconds: baseUnix + 1800),
      ];

      final suggestions = [
        const MatchSuggestion(
          matchKey: 'qm1',
          confidence: MatchSuggestionConfidence.high,
        ),
        const MatchSuggestion(
          matchKey: 'qm1',
          confidence: MatchSuggestionConfidence.high,
        ),
        const MatchSuggestion(
          matchKey: 'qm1',
          confidence: MatchSuggestionConfidence.high,
        ),
      ];

      final manuallySetRows = <int>{};

      MatchSuggester.cascadeMatchChange(
        suggestions: suggestions,
        rowIndex: 0,
        newMatchKey: 'qm1',
        schedule: schedule,
        manuallySetRows: manuallySetRows,
      );

      expect(suggestions[1].matchKey, 'qm2');
      expect(suggestions[2].matchKey, 'qm3');
    });

    test('cascade stops at manually set rows', () {
      final schedule = [
        makeMatch(key: 'qm1', timeUnixSeconds: baseUnix),
        makeMatch(key: 'qm2', timeUnixSeconds: baseUnix + 900),
        makeMatch(key: 'qm3', timeUnixSeconds: baseUnix + 1800),
        makeMatch(key: 'qm4', timeUnixSeconds: baseUnix + 2700),
      ];

      final suggestions = [
        const MatchSuggestion(
          matchKey: 'qm1',
          confidence: MatchSuggestionConfidence.high,
        ),
        const MatchSuggestion(
          matchKey: 'qm1',
          confidence: MatchSuggestionConfidence.high,
        ),
        const MatchSuggestion(
          matchKey: 'qm3', // manually set
          confidence: MatchSuggestionConfidence.high,
        ),
        const MatchSuggestion(
          matchKey: 'qm1',
          confidence: MatchSuggestionConfidence.high,
        ),
      ];

      final manuallySetRows = <int>{2}; // row 2 is manually set

      MatchSuggester.cascadeMatchChange(
        suggestions: suggestions,
        rowIndex: 0,
        newMatchKey: 'qm1',
        schedule: schedule,
        manuallySetRows: manuallySetRows,
      );

      expect(suggestions[1].matchKey, 'qm2'); // cascaded
      expect(suggestions[2].matchKey, 'qm3'); // NOT changed (manually set)
      expect(suggestions[3].matchKey, 'qm1'); // NOT changed (after manual)
    });
  });
}
