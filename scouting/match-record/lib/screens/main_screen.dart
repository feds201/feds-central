import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/data_store.dart';
import '../data/models.dart';
import '../tba/tba_client.dart';
import '../tabs/alliances_tab.dart';
import '../tabs/matches_tab.dart';
import '../tabs/search_tab.dart';
import '../tabs/teams_tab.dart';
import '../util/constants.dart';
import '../util/result.dart';
import '../util/test_flags.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/autocomplete_overlay.dart';
import '../widgets/sync_button.dart';
import 'settings_page.dart';
import 'video_viewer.dart';

class MainScreen extends StatefulWidget {
  final DataStore dataStore;
  final TbaClient tbaClient;

  const MainScreen({
    super.key,
    required this.dataStore,
    required this.tbaClient,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab = 2;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final List<SearchChip> _chips = [];
  SearchFilterMode _searchFilterMode = SearchFilterMode.union;
  List<AutocompleteResult> _autocompleteResults = [];
  Timer? _debounceTimer;
  bool _showAutocomplete = false;
  bool _isAutoLoading = false;

  // m10: Auto TBA sync
  Timer? _autoSyncTimer;
  bool _isTbaSyncing = false;

  final _searchBarKey = GlobalKey();

  DataStore get _dataStore => widget.dataStore;
  TbaClient get _tbaClient => widget.tbaClient;

  @override
  void initState() {
    super.initState();
    // Failsafe: ensure orientation is unlocked whenever we return to main screen
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _searchFocusNode.addListener(_onFocusChange);
    _maybeAutoLoad();
    _startAutoSync();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _autoSyncTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus) {
      setState(() => _showAutocomplete = false);
    }
  }

  // m10: Auto TBA sync on connectivity
  void _startAutoSync() {
    // Attempt sync on app open
    _attemptTbaSync();
    // Sync every 5 minutes
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _attemptTbaSync(),
    );
  }

  /// Silently attempts a TBA data sync if connected and events are configured.
  /// Used for auto-sync on app open and periodic background sync.
  Future<void> attemptTbaSync() => _attemptTbaSync();

  Future<void> _attemptTbaSync() async {
    final eventKeys = _dataStore.settings.selectedEventKeys;
    if (eventKeys.isEmpty) return;
    if (_isTbaSyncing) return;
    if (!_tbaClient.hasApiKey) return;

    // Check connectivity by attempting a DNS lookup
    try {
      final result = await InternetAddress.lookup('thebluealliance.com');
      if (result.isEmpty || result.first.rawAddress.isEmpty) return;
    } on SocketException {
      return;
    }

    _isTbaSyncing = true;
    try {
      for (final eventKey in eventKeys) {
        final eventResult = await _tbaClient.getEvent(eventKey);
        if (eventResult is Ok<Event>) {
          final existingKeys =
              _dataStore.events.map((e) => e.eventKey).toSet();
          if (!existingKeys.contains(eventKey)) {
            await _dataStore.setEvents([..._dataStore.events, eventResult.value]);
          } else {
            final updated = _dataStore.events
                .map((e) => e.eventKey == eventKey ? eventResult.value : e)
                .toList();
            await _dataStore.setEvents(updated);
          }
        }

        final teamsResult = await _tbaClient.getTeams(eventKey);
        if (teamsResult is Ok<List<Team>>) {
          await _dataStore.setTeamsForEvent(eventKey, teamsResult.value);
        }

        final matchesResult = await _tbaClient.getMatches(eventKey);
        if (matchesResult is Ok<List<Match>>) {
          await _dataStore.setMatchesForEvent(eventKey, matchesResult.value);
        }

        final alliancesResult = await _tbaClient.getAlliances(eventKey);
        if (alliancesResult is Ok<List<Alliance>?>) {
          final alliances = alliancesResult.value;
          if (alliances != null) {
            await _dataStore.setAlliancesForEvent(eventKey, alliances);
          }
        }
      }

      // Update last fetch time on success
      await _dataStore.updateSettings(
        _dataStore.settings.copyWith(
          lastTbaFetchTime: () => DateTime.now(),
        ),
      );
    } finally {
      _isTbaSyncing = false;
    }
  }

  Future<void> _maybeAutoLoad() async {
    if (!TestFlags.forceEventId) return;
    if (_dataStore.events.isNotEmpty) return;
    if (!_tbaClient.hasApiKey) return;

    setState(() => _isAutoLoading = true);

    const eventKey = TestFlags.forcedEventId;

    final eventResult = await _tbaClient.getEvent(eventKey);
    if (eventResult is Ok<Event>) {
      await _dataStore.setEvents([eventResult.value]);
      await _dataStore.updateSettings(
        _dataStore.settings.copyWith(selectedEventKeys: [eventKey]),
      );
    }

    final teamsResult = await _tbaClient.getTeams(eventKey);
    if (teamsResult is Ok<List<Team>>) {
      await _dataStore.setTeamsForEvent(eventKey, teamsResult.value);
    }

    final matchesResult = await _tbaClient.getMatches(eventKey);
    if (matchesResult is Ok<List<Match>>) {
      await _dataStore.setMatchesForEvent(eventKey, matchesResult.value);
    }

    final alliancesResult = await _tbaClient.getAlliances(eventKey);
    if (alliancesResult is Ok<List<Alliance>?>) {
      final alliances = alliancesResult.value;
      if (alliances != null) {
        await _dataStore.setAlliancesForEvent(eventKey, alliances);
      }
    }

    if (mounted) {
      setState(() => _isAutoLoading = false);
    }
  }

  void _onSearchTextChanged(String text) {
    _debounceTimer?.cancel();
    if (text.isEmpty) {
      setState(() {
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        final results = _computeAutocomplete(text);
        setState(() {
          _autocompleteResults = results;
          _showAutocomplete = results.isNotEmpty;
        });
      },
    );
  }

  List<AutocompleteResult> _computeAutocomplete(String query) {
    final results = <AutocompleteResult>[];
    final lowerQuery = query.toLowerCase();
    final eventKeys = _dataStore.settings.selectedEventKeys;
    final numQuery = int.tryParse(query);

    // Teams
    final teams = _dataStore.getTeamsForEvents(eventKeys);
    for (final team in teams) {
      if (team.teamNumber.toString().contains(query) ||
          team.nickname.toLowerCase().contains(lowerQuery)) {
        results.add(AutocompleteResult.team(team));
      }
    }

    // Matches
    final matches = _dataStore.getMatchesWithVideosFiltered(eventKeys);
    for (final mwv in matches) {
      if (mwv.match.displayName.toLowerCase().contains(lowerQuery)) {
        results.add(AutocompleteResult.match(mwv));
      } else if (numQuery != null && mwv.match.matchNumber == numQuery) {
        results.add(AutocompleteResult.match(mwv));
      }
    }

    // Alliances
    final alliances = _dataStore.getAlliancesForEvents(eventKeys);
    for (final alliance in alliances) {
      if (alliance.name.toLowerCase().contains(lowerQuery) ||
          alliance.allianceNumber.toString() == query) {
        results.add(AutocompleteResult.alliance(alliance));
      }
    }

    // Limit results
    if (results.length > 20) return results.sublist(0, 20);
    return results;
  }

  void _onAutocompleteResultTap(AutocompleteResult result) {
    setState(() {
      _showAutocomplete = false;
      _searchController.clear();
    });

    switch (result.type) {
      case AutocompleteResultType.team:
        final team = result.team!;
        _addChip(SearchChip.team(team.teamNumber, '${team.teamNumber}'));
      case AutocompleteResultType.match:
        _onMatchTap(result.matchWithVideos!);
      case AutocompleteResultType.alliance:
        final alliance = result.alliance!;
        _addChip(SearchChip.alliance(alliance.name, alliance.picks));
    }
  }

  void _onSubmitted() {
    if (_autocompleteResults.isNotEmpty) {
      _onAutocompleteResultTap(_autocompleteResults.first);
    }
  }

  void _addChip(SearchChip chip) {
    if (_chips.contains(chip)) return;
    setState(() {
      _chips.add(chip);
      _selectedTab = 0;
    });
  }

  void _removeChip(SearchChip chip) {
    setState(() => _chips.remove(chip));
  }

  void _onTeamTap(Team team) {
    _addChip(SearchChip.team(team.teamNumber, '${team.teamNumber}'));
  }

  void _onAllianceTap(Alliance alliance) {
    _addChip(SearchChip.alliance(alliance.name, alliance.picks));
  }

  // m11: unfocus search bar before navigating away
  void _onMatchTap(MatchWithVideos mwv) {
    if (!mwv.hasRecordings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No recordings for ${mwv.match.displayName}'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    _searchFocusNode.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoViewer(
          matchWithVideos: mwv,
          dataStore: _dataStore,
        ),
      ),
    );
  }

  bool get _showAlliances => _dataStore.hasAllianceData;

  int get _tabCount => _showAlliances ? 4 : 3;

  int get _defaultMatchesIndex => _showAlliances ? 2 : 1;

  // m3: Tab indicator colors
  static const _tabColors = [
    AppColors.searchCategory,
    AppColors.teamCategory,
    AppColors.matchCategory,
    AppColors.allianceCategory,
  ];

  // m9: Format last TBA fetch time in short format
  String _formatFetchTime(DateTime time) {
    final h = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final m = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'pm' : 'am';
    return '${time.month}/${time.day} $h:$m$amPm';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dataStore,
      builder: (context, _) {
        if (_selectedTab >= _tabCount) {
          _selectedTab = _defaultMatchesIndex;
        }

        // m4: only show search bar on the Search tab (index 0)
        final bool isSearchTab = _selectedTab == 0;

        return Scaffold(
          appBar: AppBar(
            // m9: change title from "Match Record" to "Matches"
            title: const Text('Matches'),
            bottom: isSearchTab
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: SizedBox(
                      height: 48,
                      child: ClipRect(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _searchFilterMode == SearchFilterMode.union
                                      ? Icons.join_full
                                      : Icons.join_inner,
                                  size: 20,
                                ),
                                tooltip: _searchFilterMode == SearchFilterMode.union
                                    ? 'Union: matches with ANY team'
                                    : 'Intersect: matches with ALL teams',
                                onPressed: () {
                                  setState(() {
                                    _searchFilterMode =
                                        _searchFilterMode == SearchFilterMode.union
                                            ? SearchFilterMode.intersect
                                            : SearchFilterMode.union;
                                  });
                                },
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: AppSearchBar(
                                  key: _searchBarKey,
                                  controller: _searchController,
                                  chips: _chips,
                                  focusNode: _searchFocusNode,
                                  onTextChanged: _onSearchTextChanged,
                                  onChipRemoved: _removeChip,
                                  onSubmitted: _onSubmitted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            actions: [
              // m9: TBA refetch button with last sync time
              _buildTbaRefetchButton(),
              IconButton(
                icon: Icon(
                  _dataStore.settings.recordedMatchesOnly
                      ? Icons.videocam
                      : Icons.videocam_off,
                  color: _dataStore.settings.recordedMatchesOnly
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: _dataStore.settings.recordedMatchesOnly
                    ? 'Show all matches'
                    : 'Show recorded matches only',
                onPressed: () {
                  _dataStore.updateSettings(
                    _dataStore.settings.copyWith(
                      recordedMatchesOnly:
                          !_dataStore.settings.recordedMatchesOnly,
                    ),
                  );
                },
              ),
              SyncButton(dataStore: _dataStore),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  // m11: unfocus search bar before navigating
                  _searchFocusNode.unfocus();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettingsPage(
                        dataStore: _dataStore,
                        tbaClient: _tbaClient,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              if (_isAutoLoading)
                const Center(child: CircularProgressIndicator())
              else
                IndexedStack(
                  index: _selectedTab,
                  children: [
                    SearchTab(
                      dataStore: _dataStore,
                      chips: _chips,
                      filterMode: _searchFilterMode,
                      onMatchTap: _onMatchTap,
                    ),
                    TeamsTab(
                      dataStore: _dataStore,
                      onTeamTap: _onTeamTap,
                    ),
                    MatchesTab(
                      dataStore: _dataStore,
                      onMatchTap: _onMatchTap,
                    ),
                    if (_showAlliances)
                      AlliancesTab(
                        dataStore: _dataStore,
                        onAllianceTap: _onAllianceTap,
                      ),
                  ],
                ),
              if (_showAutocomplete && _autocompleteResults.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  child: AutocompleteOverlay(
                    results: _autocompleteResults,
                    onResultTap: _onAutocompleteResultTap,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) {
              // m4: if tapping Search tab while already on it, focus the search bar
              if (index == 0 && _selectedTab == 0) {
                _searchFocusNode.requestFocus();
              }
              setState(() {
                _selectedTab = index;
                _showAutocomplete = false;
              });
            },
            destinations: [
              // m3: colored indicator lines on tab icons
              NavigationDestination(
                icon: Icon(Icons.search, color: _tabColors[0]),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.group, color: _tabColors[1]),
                label: 'Teams',
              ),
              NavigationDestination(
                icon: Icon(Icons.sports_esports, color: _tabColors[2]),
                label: 'Matches',
              ),
              if (_showAlliances)
                NavigationDestination(
                  icon: Icon(Icons.handshake, color: _tabColors[3]),
                  label: 'Alliances',
                ),
            ],
          ),
        );
      },
    );
  }

  // m9: TBA refetch button with last sync time tooltip and visible timestamp
  Widget _buildTbaRefetchButton() {
    final lastFetch = _dataStore.settings.lastTbaFetchTime;
    final hasEvents = _dataStore.settings.selectedEventKeys.isNotEmpty;
    final tooltip = lastFetch != null
        ? 'Sync TBA data (last: ${_formatFetchTime(lastFetch)})'
        : 'Sync TBA data';

    final icon = _isTbaSyncing
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.cloud_sync);

    // Show timestamp as small text below the icon when available
    if (lastFetch != null) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: hasEvents && !_isTbaSyncing
              ? () async {
                  setState(() => _isTbaSyncing = true);
                  await _attemptTbaSync();
                  if (mounted) {
                    setState(() => _isTbaSyncing = false);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                Text(
                  _formatFetchTime(lastFetch),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return IconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: hasEvents && !_isTbaSyncing
          ? () async {
              setState(() => _isTbaSyncing = true);
              await _attemptTbaSync();
              if (mounted) {
                setState(() => _isTbaSyncing = false);
              }
            }
          : null,
    );
  }
}
