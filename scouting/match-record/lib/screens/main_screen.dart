import 'dart:async';

import 'package:flutter/material.dart';

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
  List<AutocompleteResult> _autocompleteResults = [];
  Timer? _debounceTimer;
  bool _showAutocomplete = false;
  bool _isAutoLoading = false;

  final _searchBarKey = GlobalKey();

  DataStore get _dataStore => widget.dataStore;
  TbaClient get _tbaClient => widget.tbaClient;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    _maybeAutoLoad();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

  Future<void> _maybeAutoLoad() async {
    if (!TestFlags.forceEventId) return;
    if (_dataStore.events.isNotEmpty) return;

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dataStore,
      builder: (context, _) {
        if (_selectedTab >= _tabCount) {
          _selectedTab = _defaultMatchesIndex;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Match Record'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: SizedBox(
                height: 48,
                child: ClipRect(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                ),
              ),
            ),
            actions: [
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
              setState(() {
                _selectedTab = index;
                _showAutocomplete = false;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              const NavigationDestination(
                icon: Icon(Icons.group),
                label: 'Teams',
              ),
              const NavigationDestination(
                icon: Icon(Icons.sports_esports),
                label: 'Matches',
              ),
              if (_showAlliances)
                const NavigationDestination(
                  icon: Icon(Icons.handshake),
                  label: 'Alliances',
                ),
            ],
          ),
        );
      },
    );
  }
}
