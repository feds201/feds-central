import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:match_record/data/data_store.dart';
import 'package:match_record/data/json_persistence.dart';
import 'package:match_record/data/models.dart';
import 'package:match_record/sync/storage_tab.dart';

class FakeJsonPersistence extends JsonPersistence {
  AppData _data = AppData.empty();

  FakeJsonPersistence() : super(directoryPath: '/fake');

  @override
  Future<AppData> load() async => _data;

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}

Recording makeRecording({
  String id = 'rec1',
  String eventKey = '2026mimid',
  String matchKey = '2026mimid_qm1',
  String allianceSide = 'red',
  int team1 = 100,
  int team2 = 200,
  int team3 = 300,
}) {
  return Recording(
    id: id,
    eventKey: eventKey,
    matchKey: matchKey,
    allianceSide: allianceSide,
    fileExtension: '.mp4',
    recordingStartTime: DateTime(2026, 3, 20, 10, 0),
    durationMs: 60000,
    fileSizeBytes: 1024 * 1024,
    sourceDeviceType: 'android',
    originalFilename: 'video.mp4',
    team1: team1,
    team2: team2,
    team3: team3,
  );
}

Event makeEvent({
  String key = '2026mimid',
  String name = 'Midland',
  String shortName = 'Mid',
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Event(
    eventKey: key,
    name: name,
    shortName: shortName,
    startDate: startDate ?? DateTime(2026, 3, 20),
    endDate: endDate ?? DateTime(2026, 3, 22),
    playoffType: 10,
    timezone: 'America/Detroit',
  );
}

Widget buildTestWidget(StorageTab tab) {
  // Use a wide enough surface so selection buttons don't scroll off-screen
  return MaterialApp(
    home: Scaffold(body: tab),
  );
}

/// Taps a button even if it's in a horizontal scroll view.
Future<void> tapButton(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late DataStore dataStore;
  late FakeJsonPersistence persistence;

  setUp(() async {
    persistence = FakeJsonPersistence();
    dataStore = DataStore(persistence);
    await dataStore.init();
  });

  group('StorageTab empty state', () {
    testWidgets('shows empty message when no recordings exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      expect(find.text('No imported videos'), findsOneWidget);
      expect(find.text('Import videos from the Import tab'), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });
  });

  group('StorageTab with recordings', () {
    setUp(() async {
      await dataStore.setEvents([makeEvent()]);
      await dataStore.addRecording(makeRecording(id: 'rec1', matchKey: '2026mimid_qm1'));
      await dataStore.addRecording(makeRecording(id: 'rec2', matchKey: '2026mimid_qm2'));
      await dataStore.addRecording(makeRecording(id: 'rec3', matchKey: '2026mimid_qm3'));
    });

    testWidgets('shows recording count in header', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      expect(find.text('3 recordings'), findsOneWidget);
    });

    testWidgets('shows selection mode buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      expect(find.text('Select All'), findsOneWidget);
      expect(find.text('All But Ours'), findsOneWidget);
      expect(find.text('Past Events'), findsOneWidget);
      // Deselect is only shown when something is selected
      expect(find.text('Deselect'), findsNothing);
    });

    testWidgets('Select All selects all recordings and shows delete button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'Select All');

      // Delete button should appear with count
      expect(find.text('Delete 3 Video(s)'), findsOneWidget);
      // Deselect button should appear
      expect(find.text('Deselect'), findsOneWidget);
    });

    testWidgets('Deselect clears selection and hides delete button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      // Select all first
      await tapButton(tester, 'Select All');
      expect(find.text('Delete 3 Video(s)'), findsOneWidget);

      // Deselect
      await tapButton(tester, 'Deselect');

      // Delete button should be gone
      expect(find.textContaining('Delete'), findsNothing);
      expect(find.text('Deselect'), findsNothing);
    });

    testWidgets('delete button has correct styling (not full width, with icon)', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'Select All');

      // Verify the delete button exists with correct text and icon
      expect(find.text('Delete 3 Video(s)'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // Verify there is no SizedBox with infinite width wrapping the button
      // (the old code used SizedBox(width: double.infinity))
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final fullWidthSizedBoxes = sizedBoxes.where(
        (sb) => sb.width == double.infinity,
      );
      expect(fullWidthSizedBoxes, isEmpty,
          reason: 'Delete button should not be wrapped in a full-width SizedBox');
    });

    testWidgets('delete confirmation dialog shows and cancelling preserves selection',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'Select All');

      // Tap delete
      final deleteFinder = find.text('Delete 3 Video(s)');
      await tester.ensureVisible(deleteFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Videos'), findsOneWidget);
      expect(find.textContaining('Delete 3 video(s) from tablet?'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Selection should be preserved
      expect(find.text('Delete 3 Video(s)'), findsOneWidget);
    });
  });

  group('StorageTab All But Ours selection', () {
    testWidgets('selects only recordings without our team', (tester) async {
      await dataStore.updateSettings(
        dataStore.settings.copyWith(teamNumber: () => 201),
      );
      await dataStore.setEvents([makeEvent()]);

      // rec1 has our team (201), rec2 and rec3 do not
      await dataStore.addRecording(makeRecording(
        id: 'rec1',
        matchKey: '2026mimid_qm1',
        team1: 201,
        team2: 100,
        team3: 300,
      ));
      await dataStore.addRecording(makeRecording(
        id: 'rec2',
        matchKey: '2026mimid_qm2',
        team1: 400,
        team2: 500,
        team3: 600,
      ));
      await dataStore.addRecording(makeRecording(
        id: 'rec3',
        matchKey: '2026mimid_qm3',
        team1: 700,
        team2: 800,
        team3: 900,
      ));

      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'All But Ours');

      // Should select 2 recordings (not the one with team 201)
      expect(find.text('Delete 2 Video(s)'), findsOneWidget);
    });

    testWidgets('selects all when no team number is set', (tester) async {
      await dataStore.setEvents([makeEvent()]);
      await dataStore.addRecording(makeRecording(id: 'rec1', matchKey: '2026mimid_qm1'));
      await dataStore.addRecording(makeRecording(id: 'rec2', matchKey: '2026mimid_qm2'));
      await dataStore.addRecording(makeRecording(id: 'rec3', matchKey: '2026mimid_qm3'));

      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'All But Ours');

      // With no team number set, All But Ours selects everything
      expect(find.text('Delete 3 Video(s)'), findsOneWidget);
    });
  });

  group('StorageTab Past Events selection', () {
    testWidgets('selects recordings from past events only', (tester) async {
      // Create a past event and a current event
      final pastEvent = makeEvent(
        key: '2025mimid',
        shortName: 'Mid25',
        startDate: DateTime(2025, 3, 20),
        endDate: DateTime(2025, 3, 22),
      );
      final currentEvent = makeEvent(
        key: '2026mimid',
        shortName: 'Mid26',
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 12, 22),
      );
      await dataStore.setEvents([pastEvent, currentEvent]);

      await dataStore.addRecording(makeRecording(
        id: 'rec_past',
        eventKey: '2025mimid',
        matchKey: '2025mimid_qm1',
      ));
      await dataStore.addRecording(makeRecording(
        id: 'rec_current',
        eventKey: '2026mimid',
        matchKey: '2026mimid_qm1',
      ));

      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'Past Events');

      // Should select only the recording from the past event
      expect(find.text('Delete 1 Video(s)'), findsOneWidget);
    });

    testWidgets('shows snackbar when no past events exist', (tester) async {
      // Only a current/future event
      final futureEvent = makeEvent(
        key: '2026mimid',
        endDate: DateTime(2026, 12, 22),
      );
      await dataStore.setEvents([futureEvent]);
      await dataStore.addRecording(makeRecording(id: 'rec1'));

      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      await tapButton(tester, 'Past Events');

      expect(find.text('No past events found'), findsOneWidget);
      // No delete button should appear
      expect(find.textContaining('Delete'), findsNothing);
    });
  });

  group('StorageTab has no camera/quick share UI', () {
    testWidgets('does not show camera or quick share sections', (tester) async {
      await dataStore.setEvents([makeEvent()]);
      await dataStore.addRecording(makeRecording(id: 'rec1'));

      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      // No ExpansionTile-related camera/quick share UI
      expect(find.text('Camera Source Files'), findsNothing);
      expect(find.text('Quick Share Source Files'), findsNothing);
      expect(find.text('Refresh source files'), findsNothing);
      expect(find.byIcon(Icons.photo_camera), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.byIcon(Icons.delete_sweep), findsNothing);
    });
  });

  group('StorageTab individual row toggle', () {
    testWidgets('tapping a row checkbox toggles its selection', (tester) async {
      await dataStore.setEvents([makeEvent()]);
      await dataStore.addRecording(makeRecording(id: 'rec1', matchKey: '2026mimid_qm1'));

      await tester.pumpWidget(buildTestWidget(
        StorageTab(dataStore: dataStore, storageDir: '/fake/storage'),
      ));

      // Initially no delete button
      expect(find.textContaining('Delete'), findsNothing);

      // Find and tap the checkbox in the recording row
      final checkboxes = find.byType(Checkbox);
      // There should be at least one checkbox (the recording row)
      expect(checkboxes, findsAtLeastNWidgets(1));

      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Now delete button should appear
      expect(find.text('Delete 1 Video(s)'), findsOneWidget);

      // Tap again to deselect
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Delete button should be gone
      expect(find.textContaining('Delete'), findsNothing);
    });
  });
}
