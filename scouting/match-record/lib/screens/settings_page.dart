import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../tba/tba_client.dart';
import '../util/result.dart';

class SettingsPage extends StatefulWidget {
  final DataStore dataStore;
  final TbaClient tbaClient;

  const SettingsPage({
    super.key,
    required this.dataStore,
    required this.tbaClient,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _teamNumberController;
  late TextEditingController _shortVideoController;
  late TextEditingController _gapMinController;
  late TextEditingController _gapMaxController;
  late TextEditingController _scrubExponentController;
  late TextEditingController _scrubMaxRangeController;
  late TextEditingController _scrubCoalescingController;

  bool _isLoadingEvents = false;
  bool _isLoadingTbaData = false;
  List<Event>? _availableEvents;

  @override
  void initState() {
    super.initState();
    final settings = widget.dataStore.settings;
    _teamNumberController = TextEditingController(
      text: settings.teamNumber?.toString() ?? '',
    );
    _shortVideoController = TextEditingController(
      text: (settings.shortVideoThresholdMs / 1000).toStringAsFixed(0),
    );
    _gapMinController = TextEditingController(
      text: settings.sequentialGapMinMinutes.toString(),
    );
    _gapMaxController = TextEditingController(
      text: settings.sequentialGapMaxMinutes.toString(),
    );
    _scrubExponentController = TextEditingController(
      text: settings.scrubExponent.toString(),
    );
    _scrubMaxRangeController = TextEditingController(
      text: (settings.scrubMaxRangeMs / 1000).toStringAsFixed(0),
    );
    _scrubCoalescingController = TextEditingController(
      text: settings.scrubCoalescingIntervalMs.toString(),
    );
  }

  @override
  void dispose() {
    _teamNumberController.dispose();
    _shortVideoController.dispose();
    _gapMinController.dispose();
    _gapMaxController.dispose();
    _scrubExponentController.dispose();
    _scrubMaxRangeController.dispose();
    _scrubCoalescingController.dispose();
    super.dispose();
  }

  Future<void> _saveTeamNumber() async {
    final text = _teamNumberController.text.trim();
    final teamNumber = text.isEmpty ? null : int.tryParse(text);
    await widget.dataStore.updateSettings(
      widget.dataStore.settings.copyWith(teamNumber: () => teamNumber),
    );
  }

  Future<void> _saveThresholds() async {
    final shortVideo =
        (int.tryParse(_shortVideoController.text.trim()) ?? 30) * 1000;
    final gapMin = int.tryParse(_gapMinController.text.trim()) ?? 10;
    final gapMax = int.tryParse(_gapMaxController.text.trim()) ?? 20;
    final scrubExp =
        double.tryParse(_scrubExponentController.text.trim()) ?? 2.5;
    final scrubMax =
        (int.tryParse(_scrubMaxRangeController.text.trim()) ?? 120) * 1000;
    final scrubCoalescing =
        int.tryParse(_scrubCoalescingController.text.trim()) ?? 100;

    await widget.dataStore.updateSettings(
      widget.dataStore.settings.copyWith(
        shortVideoThresholdMs: shortVideo,
        sequentialGapMinMinutes: gapMin,
        sequentialGapMaxMinutes: gapMax,
        scrubExponent: scrubExp,
        scrubMaxRangeMs: scrubMax,
        scrubCoalescingIntervalMs: scrubCoalescing,
      ),
    );
  }

  Future<void> _fetchEventList() async {
    setState(() => _isLoadingEvents = true);
    final year = DateTime.now().year;
    final result = await widget.tbaClient.getEvents(year);
    setState(() => _isLoadingEvents = false);

    switch (result) {
      case Ok(:final value):
        final sorted = List<Event>.from(value)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        setState(() => _availableEvents = sorted);
      case Err(:final message):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
    }
  }

  Future<void> _addEvent() async {
    if (_availableEvents == null) {
      await _fetchEventList();
    }
    if (_availableEvents == null || !mounted) return;

    final selectedKeys = widget.dataStore.settings.selectedEventKeys.toSet();
    final unselected = _availableEvents!
        .where((e) => !selectedKeys.contains(e.eventKey))
        .toList();

    if (!mounted) return;
    final picked = await showDialog<Event>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Event'),
        children: unselected
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, e),
                  child: Text('${e.shortName} (${e.eventKey})'),
                ))
            .toList(),
      ),
    );

    if (picked != null) {
      final newKeys = [
        ...widget.dataStore.settings.selectedEventKeys,
        picked.eventKey,
      ];
      final newEvents = [...widget.dataStore.events, picked];
      await widget.dataStore.setEvents(newEvents);
      await widget.dataStore.updateSettings(
        widget.dataStore.settings.copyWith(selectedEventKeys: newKeys),
      );
      setState(() {});
    }
  }

  Future<void> _removeEvent(String eventKey) async {
    final newKeys = widget.dataStore.settings.selectedEventKeys
        .where((k) => k != eventKey)
        .toList();
    await widget.dataStore.updateSettings(
      widget.dataStore.settings.copyWith(selectedEventKeys: newKeys),
    );
    setState(() {});
  }

  Future<void> _loadTbaData() async {
    setState(() => _isLoadingTbaData = true);

    final eventKeys = widget.dataStore.settings.selectedEventKeys;
    final errors = <String>[];

    for (final eventKey in eventKeys) {
      final eventResult = await widget.tbaClient.getEvent(eventKey);
      switch (eventResult) {
        case Ok(:final value):
          final existingKeys =
              widget.dataStore.events.map((e) => e.eventKey).toSet();
          if (!existingKeys.contains(eventKey)) {
            await widget.dataStore
                .setEvents([...widget.dataStore.events, value]);
          } else {
            final updated = widget.dataStore.events
                .map((e) => e.eventKey == eventKey ? value : e)
                .toList();
            await widget.dataStore.setEvents(updated);
          }
        case Err(:final message):
          errors.add('Event $eventKey: $message');
      }

      final teamsResult = await widget.tbaClient.getTeams(eventKey);
      switch (teamsResult) {
        case Ok(:final value):
          await widget.dataStore.setTeamsForEvent(eventKey, value);
        case Err(:final message):
          errors.add('Teams $eventKey: $message');
      }

      final matchesResult = await widget.tbaClient.getMatches(eventKey);
      switch (matchesResult) {
        case Ok(:final value):
          await widget.dataStore.setMatchesForEvent(eventKey, value);
        case Err(:final message):
          errors.add('Matches $eventKey: $message');
      }

      final alliancesResult = await widget.tbaClient.getAlliances(eventKey);
      switch (alliancesResult) {
        case Ok(:final value):
          if (value != null) {
            await widget.dataStore.setAlliancesForEvent(eventKey, value);
          }
        case Err(:final message):
          errors.add('Alliances $eventKey: $message');
      }
    }

    // Update last fetch time
    await widget.dataStore.updateSettings(
      widget.dataStore.settings.copyWith(
        lastTbaFetchTime: () => DateTime.now(),
      ),
    );

    setState(() => _isLoadingTbaData = false);

    if (mounted) {
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TBA data loaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some data failed to load:\n${errors.join('\n')}')),
        );
      }
    }
  }

  String _formatFetchTime(DateTime time) {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'pm' : 'am';
    return '${time.month}/${time.day} $h:$m$amPm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.dataStore.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Team Number
          Text('Your Team Number', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _teamNumberController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 201',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _saveTeamNumber(),
          ),
          const SizedBox(height: 24),

          // Events
          Text('Events', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final key in settings.selectedEventKeys)
                InputChip(
                  label: Text(key),
                  onDeleted: () => _removeEvent(key),
                ),
              ActionChip(
                avatar: _isLoadingEvents
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 18),
                label: const Text('Add Event'),
                onPressed: _isLoadingEvents ? null : _addEvent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoadingTbaData || settings.selectedEventKeys.isEmpty
                ? null
                : _loadTbaData,
            icon: _isLoadingTbaData
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_download),
            label: Text(
                _isLoadingTbaData ? 'Loading...' : 'Load from TBA'),
          ),
          if (settings.lastTbaFetchTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Last fetched: ${_formatFetchTime(settings.lastTbaFetchTime!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Thresholds
          Text('Thresholds', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildThresholdField(
            label: 'Short video threshold (seconds)',
            controller: _shortVideoController,
            infoText: 'Videos shorter than this are auto-unchecked during import (probably accidental recordings)',
          ),
          const SizedBox(height: 8),
          _buildThresholdField(
            label: 'Sequential gap min (minutes)',
            controller: _gapMinController,
            infoText: 'If gap between consecutive videos is less than this, assume they\'re sequential matches',
          ),
          const SizedBox(height: 8),
          _buildThresholdField(
            label: 'Sequential gap max (minutes)',
            controller: _gapMaxController,
            infoText: 'If gap between consecutive videos is more than this, use match schedule timestamp instead of sequence',
          ),
          const SizedBox(height: 8),
          _buildThresholdField(
            label: 'Scrub exponent',
            controller: _scrubExponentController,
            isDecimal: true,
            infoText: 'Controls non-linearity of touch scrubbing. Higher = finer control near touch point, coarser at edges',
          ),
          const SizedBox(height: 8),
          _buildThresholdField(
            label: 'Scrub max range (seconds)',
            controller: _scrubMaxRangeController,
            infoText: 'Maximum time range (seconds) that a full-width scrub gesture covers',
          ),
          const SizedBox(height: 8),
          _buildThresholdField(
            label: 'Scrub coalescing interval (ms)',
            controller: _scrubCoalescingController,
            infoText: 'How often seek commands are sent during finger scrubbing (lower = smoother but heavier on decoder)',
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: _saveThresholds,
            child: const Text('Save Thresholds'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildThresholdField({
    required String label,
    required TextEditingController controller,
    bool isDecimal = false,
    String? infoText,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: infoText != null
            ? IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(infoText)),
                  );
                },
              )
            : null,
      ),
    );
  }
}
