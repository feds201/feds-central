import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main.dart';
import 'services/Colors.dart';
import 'services/DataBase.dart';
import 'components/SwipeCards.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data
  List<MatchRecord> _matchRecords = [];
  Map<String, PitRecord> _pitRecords = {};
  Map<String, dynamic> _qualRecords = {};
  Map<String, PitChecklistItem> _pitCheckRecords = {};

  // Search
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  // Selection mode
  bool _isSelecting = false;
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
          _exitSelectionMode();
        });
      }
    });
    _loadAllData();
  }

  void _loadAllData() {
    MatchDataBase.LoadAll();
    PitDataBase.LoadAll();
    QualitativeDataBase.LoadAll();
    PitCheckListDatabase.LoadAll();
    setState(() {
      _matchRecords = MatchDataBase.GetAll();
      final pitExport = PitDataBase.Export();
      _pitRecords = pitExport is Map<String, PitRecord>
          ? pitExport
          : <String, PitRecord>{};
      final qualExport = QualitativeDataBase.Export();
      _qualRecords = qualExport is Map<String, dynamic>
          ? qualExport
          : <String, dynamic>{};
      final pitCheckExport = PitCheckListDatabase.Export();
      _pitCheckRecords = pitCheckExport is Map<String, PitChecklistItem>
          ? pitCheckExport
          : <String, PitChecklistItem>{};
    });
  }

  void _exitSelectionMode() {
    _isSelecting = false;
    _selectedKeys.clear();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Deletion logic ──────────────────────────────────────

  void _deleteMatchByKey(String key) {
    MatchDataBase.DeleteData(key);
    MatchDataBase.SaveAll();
    _loadAllData();
  }

  void _deletePitByKey(String key) {
    PitDataBase.DeleteData(key);
    PitDataBase.SaveAll();
    _loadAllData();
  }

  void _deletePitCheckByKey(String key) {
    PitCheckListDatabase.DeleteData(key);
    PitCheckListDatabase.SaveAll();
    _loadAllData();
  }

  void _deleteQualByKey(String key) {
    QualitativeDataBase.DeleteData(key);
    QualitativeDataBase.SaveAll();
    _loadAllData();
  }

  void _deleteSelectedForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        for (final key in _selectedKeys) {
          MatchDataBase.DeleteData(key);
        }
        MatchDataBase.SaveAll();
        break;
      case 1:
        for (final key in _selectedKeys) {
          PitDataBase.DeleteData(key);
        }
        PitDataBase.SaveAll();
        break;
      case 2:
        for (final key in _selectedKeys) {
          PitCheckListDatabase.DeleteData(key);
        }
        PitCheckListDatabase.SaveAll();
        break;
      case 3:
        for (final key in _selectedKeys) {
          QualitativeDataBase.DeleteData(key);
        }
        QualitativeDataBase.SaveAll();
        break;
    }
    _exitSelectionMode();
    _loadAllData();
  }

  void _clearCurrentTab() {
    switch (_tabController.index) {
      case 0:
        MatchDataBase.ClearData();
        break;
      case 1:
        PitDataBase.ClearData();
        break;
      case 2:
        PitCheckListDatabase.ClearData();
        break;
      case 3:
        QualitativeDataBase.ClearData();
        break;
    }
    _exitSelectionMode();
    _loadAllData();
  }

  String get _currentTabName {
    switch (_tabController.index) {
      case 0:
        return 'Match';
      case 1:
        return 'Pit';
      case 2:
        return 'Checklist';
      case 3:
        return 'Qualitative';
      default:
        return '';
    }
  }

  int get _currentTabCount {
    switch (_tabController.index) {
      case 0:
        return _matchRecords.length;
      case 1:
        return _pitRecords.length;
      case 2:
        return _pitCheckRecords.length;
      case 3:
        return _qualRecords.length;
      default:
        return 0;
    }
  }

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool dark = !islightmode();
    final Color bgColor = dark ? darkColors.goodblack : lightColors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(dark, bgColor),
      body: Column(
        children: [
          if (_isSearchOpen) _buildSearchBar(dark),
          if (!_isSelecting) _buildOverviewBanner(dark),
          if (_isSelecting) _buildSelectionBar(dark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: _isSelecting
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                _buildMatchTab(dark),
                _buildPitTab(dark),
                _buildPitChecklistTab(dark),
                _buildQualitativeTab(dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────

  AppBar _buildAppBar(bool dark, Color bgColor) {
    if (_isSelecting) {
      return AppBar(
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF1A1A2E) : Colors.blue.shade50,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: dark ? Colors.white70 : Colors.black54),
          onPressed: () => setState(() => _exitSelectionMode()),
        ),
        title: Text(
          '${_selectedKeys.length} selected',
          style: GoogleFonts.museoModerno(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: false,
        actions: [
          // Select / Deselect All
          IconButton(
            icon: Icon(
              _selectedKeys.length == _currentTabCount
                  ? Icons.deselect
                  : Icons.select_all,
              color: dark ? Colors.white70 : Colors.black54,
            ),
            tooltip: _selectedKeys.length == _currentTabCount
                ? 'Deselect All'
                : 'Select All',
            onPressed: () {
              setState(() {
                if (_selectedKeys.length == _currentTabCount) {
                  _selectedKeys.clear();
                } else {
                  _selectedKeys.clear();
                  switch (_tabController.index) {
                    case 0:
                      for (final m in _matchRecords) {
                        _selectedKeys.add(m.matchKey);
                      }
                      break;
                    case 1:
                      _selectedKeys.addAll(_pitRecords.keys);
                      break;
                    case 2:
                      _selectedKeys.addAll(_pitCheckRecords.keys);
                      break;
                    case 3:
                      _selectedKeys.addAll(_qualRecords.keys);
                      break;
                  }
                }
              });
            },
          ),
          // Delete selected
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: _selectedKeys.isEmpty
                    ? (dark ? Colors.white24 : Colors.black26)
                    : Colors.redAccent),
            tooltip: 'Delete Selected',
            onPressed: _selectedKeys.isEmpty
                ? null
                : () => _showDeleteDialog(
                      'Delete ${_selectedKeys.length} $_currentTabName log${_selectedKeys.length == 1 ? '' : 's'}?',
                      'This action cannot be undone.',
                      _deleteSelectedForCurrentTab,
                    ),
          ),
        ],
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: bgColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back,
            color: dark ? Colors.white70 : Colors.black54),
        onPressed: () => Navigator.pop(context),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.redAccent, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'Scouting Logs',
          style: GoogleFonts.museoModerno(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _isSearchOpen ? Icons.search_off : Icons.search,
            color: dark ? Colors.white70 : Colors.black54,
          ),
          onPressed: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert,
              color: dark ? Colors.white70 : Colors.black54),
          color: dark ? const Color(0xFF1E1E1E) : Colors.white,
          onSelected: (value) {
            switch (value) {
              case 'delete_all':
                if (_currentTabCount > 0) {
                  _showDeleteDialog(
                    'Delete all $_currentTabName logs?',
                    'This will permanently remove ${_currentTabCount} log${_currentTabCount == 1 ? '' : 's'}.',
                    _clearCurrentTab,
                  );
                }
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete_all',
              enabled: _currentTabCount > 0,
              child: Row(
                children: [
                  Icon(Icons.delete_sweep,
                      color: _currentTabCount > 0
                          ? Colors.redAccent
                          : Colors.grey,
                      size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Delete All $_currentTabName Logs',
                    style: TextStyle(
                      color: _currentTabCount > 0
                          ? (dark ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: dark ? Colors.white : Colors.black87,
        unselectedLabelColor: dark ? Colors.white38 : Colors.black38,
        indicatorColor: Colors.blueAccent,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.museoModerno(
            fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.museoModerno(fontSize: 12),
        tabs: [
          Tab(icon: Icon(Icons.sports_score, size: 18), text: 'Match'),
          Tab(icon: Icon(Icons.assignment, size: 18), text: 'Pit'),
          Tab(icon: Icon(Icons.checklist, size: 18), text: 'Checklist'),
          Tab(icon: Icon(Icons.question_answer, size: 18), text: 'Qual'),
        ],
      ),
    );
  }

  // ─── Delete Confirmation Dialog ──────────────────────────

  void _showDeleteDialog(String title, String message, VoidCallback onConfirm) {
    final dark = !islightmode();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(title,
                  style: GoogleFonts.museoModerno(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black87)),
            ),
          ],
        ),
        content: Text(message,
            style: TextStyle(
                color: dark ? Colors.white60 : Colors.black54, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(
                    color: dark ? Colors.white54 : Colors.black45)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────

  Widget _buildSearchBar(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: dark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search logs...',
          hintStyle: TextStyle(
              color: dark ? Colors.white38 : Colors.black38, fontSize: 14),
          prefixIcon: Icon(Icons.search,
              color: dark ? Colors.white38 : Colors.black38),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: dark ? Colors.white38 : Colors.black38),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: dark
              ? const Color.fromARGB(255, 30, 30, 30)
              : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  // ─── Selection Bar ───────────────────────────────────────

  Widget _buildSelectionBar(bool dark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF2A1A1A), const Color(0xFF1A1A2A)]
              : [Colors.red.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: dark ? Colors.redAccent.withOpacity(0.3) : Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap cards to select • Swipe left to delete one',
              style: TextStyle(
                  fontSize: 12,
                  color: dark ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Overview Banner ─────────────────────────────────────

  Widget _buildOverviewBanner(bool dark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: dark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniStat(Icons.sports_score, _matchRecords.length.toString(),
              'Match', Colors.green, dark),
          _miniDivider(dark),
          _miniStat(Icons.assignment, _pitRecords.length.toString(), 'Pit',
              Colors.blue, dark),
          _miniDivider(dark),
          _miniStat(Icons.checklist, _pitCheckRecords.length.toString(),
              'Check', Colors.orange, dark),
          _miniDivider(dark),
          _miniStat(Icons.question_answer, _qualRecords.length.toString(),
              'Qual', Colors.purple, dark),
        ],
      ),
    );
  }

  Widget _miniStat(
      IconData icon, String value, String label, Color color, bool dark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.museoModerno(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: dark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _miniDivider(bool dark) {
    return Container(
        height: 32,
        width: 1,
        color: dark ? Colors.white12 : Colors.grey.shade300);
  }

  // ─── Empty State ─────────────────────────────────────────

  Widget _buildEmptyTab(
      bool dark, IconData icon, String title, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(dark ? 0.1 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 40, color: color.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.museoModerno(
                  fontSize: 18,
                  color: dark ? Colors.white54 : Colors.black45)),
          const SizedBox(height: 6),
          Text('Scouted data will appear here',
              style: TextStyle(
                  fontSize: 13,
                  color: dark ? Colors.white30 : Colors.black26)),
        ],
      ),
    );
  }

  // ─── Dismiss Background ──────────────────────────────────

  Widget _swipeBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 22),
          SizedBox(width: 6),
          Text('Delete',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Wrap card with Dismissible + selection ──────────────

  Widget _wrapCard(String key, Widget card, VoidCallback onDelete, bool dark) {
    if (_isSelecting) {
      final isSelected = _selectedKeys.contains(key);
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedKeys.remove(key);
            } else {
              _selectedKeys.add(key);
            }
          });
        },
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: Colors.redAccent, width: 2)
                    : null,
              ),
              child: card,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.redAccent : Colors.transparent,
                  border: Border.all(
                      color: isSelected
                          ? Colors.redAccent
                          : (dark ? Colors.white38 : Colors.black26),
                      width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: Key('dismiss_$key'),
      direction: DismissDirection.endToStart,
      background: _swipeBackground(),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor:
                    dark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Delete this log?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _isSelecting = true;
            _selectedKeys.add(key);
          });
        },
        child: card,
      ),
    );
  }

  // ─── MATCH TAB ───────────────────────────────────────────

  Widget _buildMatchTab(bool dark) {
    final q = _searchQuery.toLowerCase();
    final filtered = q.isEmpty
        ? _matchRecords
        : _matchRecords.where((m) {
            return m.teamNumber.toLowerCase().contains(q) ||
                m.matchKey.toLowerCase().contains(q) ||
                m.eventKey.toLowerCase().contains(q) ||
                m.scouterName.toLowerCase().contains(q);
          }).toList();

    if (_matchRecords.isEmpty) {
      return _buildEmptyTab(
          dark, Icons.sports_score, 'No Match Logs', Colors.green);
    }
    if (filtered.isEmpty) return _buildNoResults(dark);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final m = filtered[index];
        final key = m.matchKey;
        final isRed = m.allianceColor == 'Red';
        final accent = isRed ? Colors.redAccent : Colors.blueAccent;
        final cardBg =
            dark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white;

        final card = Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            shadowColor: accent.withOpacity(0.3),
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: accent.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isSelecting ? null : () => _showMatchDetail(m, dark),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRed
                              ? [Colors.red.shade700, Colors.red.shade400]
                              : [Colors.blue.shade700, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          m.teamNumber.replaceAll('frc', ''),
                          style: GoogleFonts.museoModerno(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.matchKey,
                              style: GoogleFonts.museoModerno(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      dark ? Colors.white : Colors.black87),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Row(children: [
                            Icon(Icons.person_outline,
                                size: 13,
                                color:
                                    dark ? Colors.white54 : Colors.black45),
                            const SizedBox(width: 4),
                            Text(m.scouterName,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: dark
                                        ? Colors.white54
                                        : Colors.black45)),
                            const SizedBox(width: 8),
                            _chip('${m.allianceColor} ${m.station}', accent,
                                dark),
                          ]),
                        ],
                      ),
                    ),
                    if (!_isSelecting)
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: dark ? Colors.white30 : Colors.black26),
                  ],
                ),
              ),
            ),
          ),
        );

        return _wrapCard(key, card, () => _deleteMatchByKey(key), dark);
      },
    );
  }

  void _showMatchDetail(MatchRecord match, bool dark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: dark ? darkColors.goodblack : lightColors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: dark ? darkColors.goodblack : lightColors.white,
            leading: IconButton(
                icon: Icon(Icons.arrow_back,
                    color: dark ? Colors.white70 : Colors.black54),
                onPressed: () => Navigator.pop(context)),
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: match.allianceColor == 'Red'
                    ? [Colors.red, Colors.redAccent]
                    : [Colors.blue, Colors.blueAccent],
              ).createShader(bounds),
              child: Text(
                  'Team ${match.teamNumber.replaceAll('frc', '')}',
                  style: GoogleFonts.museoModerno(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: MatchCard(
              matchData: match.toCsv(),
              teamNumber: match.teamNumber,
              eventName: match.eventKey,
              allianceColor: match.allianceColor,
              selectedStation: match.station.toString(),
              matchKey: match.matchKey,
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // ─── PIT TAB ─────────────────────────────────────────────

  Widget _buildPitTab(bool dark) {
    final entries = _pitRecords.entries.toList();
    final q = _searchQuery.toLowerCase();
    final filtered = q.isEmpty
        ? entries
        : entries.where((e) {
            final r = e.value;
            return r.teamNumber.toString().contains(q) ||
                r.scouterName.toLowerCase().contains(q) ||
                r.eventKey.toLowerCase().contains(q) ||
                r.driveTrainType.toLowerCase().contains(q);
          }).toList();

    if (entries.isEmpty) {
      return _buildEmptyTab(
          dark, Icons.assignment, 'No Pit Scouting Logs', Colors.blue);
    }
    if (filtered.isEmpty) return _buildNoResults(dark);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final key = filtered[index].key;
        final r = filtered[index].value;
        final cardBg =
            dark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white;

        final card = Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: Colors.blueAccent.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isSelecting ? null : () => _showPitDetail(dark, r),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(r.teamNumber.toString(),
                            style: GoogleFonts.museoModerno(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Team ${r.teamNumber}',
                              style: GoogleFonts.museoModerno(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      dark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.person_outline,
                                size: 13,
                                color: dark ? Colors.white54 : Colors.black45),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(r.scouterName,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: dark
                                          ? Colors.white54
                                          : Colors.black45),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (r.driveTrainType.isNotEmpty)
                                _chip(r.driveTrainType, Colors.blue, dark),
                              if (r.weight > 0)
                                _chip('${r.weight.toStringAsFixed(1)} lbs',
                                    Colors.teal, dark),
                              if (r.speed > 0)
                                _chip('${r.speed.toStringAsFixed(1)} ft/s',
                                    Colors.orange, dark),
                              if (r.climbType.isNotEmpty)
                                _chip(r.climbType.first, Colors.purple, dark),
                              if (r.batteries > 0)
                                _chip('${r.batteries} batt', Colors.green, dark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelecting)
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: dark ? Colors.white30 : Colors.black26),
                  ],
                ),
              ),
            ),
          ),
        );

        return _wrapCard(key, card, () => _deletePitByKey(key), dark);
      },
    );
  }

  void _showPitDetail(bool dark, PitRecord r) {
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white54 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          dark ? const Color.fromARGB(255, 25, 25, 25) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade700, Colors.blue.shade400],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(r.teamNumber.toString(),
                              style: GoogleFonts.museoModerno(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Team ${r.teamNumber}',
                                style: GoogleFonts.museoModerno(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            if (r.scouterName.isNotEmpty)
                              Text('Scouted by ${r.scouterName}',
                                  style: TextStyle(fontSize: 13, color: subColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Robot Specs
                  Text('Robot Specs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _pitStatTile('Drivetrain', r.driveTrainType.isNotEmpty ? r.driveTrainType : '—', Colors.blue, dark)),
                      const SizedBox(width: 10),
                      Expanded(child: _pitStatTile('Weight', r.weight > 0 ? '${r.weight.toStringAsFixed(1)} lbs' : '—', Colors.teal, dark)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _pitStatTile('Speed', r.speed > 0 ? '${r.speed.toStringAsFixed(1)} ft/s' : '—', Colors.orange, dark)),
                      const SizedBox(width: 10),
                      Expanded(child: _pitStatTile('Batteries', r.batteries > 0 ? '${r.batteries}' : '—', Colors.green, dark)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Capabilities
                  Text('Capabilities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (r.autonType.isNotEmpty)
                        _chip('Auto: ${r.autonType}', Colors.indigo, dark),
                      ...r.scoreType.map((s) => _chip(s, Colors.amber.shade700, dark)),
                      ...r.scoreObject.map((s) => _chip(s, Colors.deepOrange, dark)),
                      ...r.intake.map((s) => _chip('Intake: $s', Colors.cyan, dark)),
                      ...r.climbType.map((s) => _chip('Climb: $s', Colors.purple, dark)),
                    ],
                  ),

                  if (r.driveMotorType.isNotEmpty || r.framePerimeter.isNotEmpty || r.groundClearance > 0) ...[
                    const SizedBox(height: 20),
                    Text('Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (r.driveMotorType.isNotEmpty)
                          _chip('Motor: ${r.driveMotorType}', Colors.blueGrey, dark),
                        if (r.framePerimeter.isNotEmpty)
                          _chip('Frame: ${r.framePerimeter}', Colors.brown, dark),
                        if (r.groundClearance > 0)
                          _chip('Clearance: ${r.groundClearance.toStringAsFixed(1)}"', Colors.lime.shade700, dark),
                        if (r.avgCycleTime > 0)
                          _chip('Cycle: ${r.avgCycleTime.toStringAsFixed(1)}s', Colors.pink, dark),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _pitStatTile(String label, String value, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  // ─── PIT CHECKLIST TAB ───────────────────────────────────

  Widget _buildPitChecklistTab(bool dark) {
    final entries = _pitCheckRecords.entries.toList();
    final q = _searchQuery.toLowerCase();
    final filtered = q.isEmpty
        ? entries
        : entries.where((e) {
            return e.key.toLowerCase().contains(q) ||
                e.value.matchkey.toLowerCase().contains(q) ||
                e.value.note.toLowerCase().contains(q);
          }).toList();

    if (entries.isEmpty) {
      return _buildEmptyTab(
          dark, Icons.checklist, 'No Pit Checklist Logs', Colors.orange);
    }
    if (filtered.isEmpty) return _buildNoResults(dark);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final key = filtered[index].key;
        final item = filtered[index].value;
        final cardBg =
            dark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white;

        int total = 6;
        int done = 0;
        if (item.drive_motors &&
            item.drive_wheels &&
            item.drive_gearboxes &&
            item.drive_wires &&
            item.drive_nuts_and_bolts) done++;
        if (item.structure_frame &&
            item.structure_hopper_panels &&
            item.structure_brain_pan &&
            item.structure_belly_pan &&
            item.structure_nuts_and_bolts) done++;
        if (item.intake_rack &&
            item.intake_pinion &&
            item.intake_belts &&
            item.intake_roller &&
            item.intake_motors &&
            item.intake_nuts_and_bolts) done++;
        if (item.spindexer_panel &&
            item.spindexer_churros &&
            item.spindexer_motor &&
            item.spindexer_wheels &&
            item.spindexer_nuts_and_bolts) done++;
        if (item.kicker_plates &&
            item.kicker_roller &&
            item.kicker_belts &&
            item.kicker_gears &&
            item.kicker_motor &&
            item.kicker_nuts_and_bolts) done++;
        if (item.shooter_flywheels &&
            item.shooter_hood &&
            item.shooter_gears &&
            item.shooter_motors &&
            item.shooter_nuts_and_bolts) done++;

        double progress = done / total;
        Color progressColor = progress >= 1.0
            ? Colors.green
            : progress >= 0.5
                ? Colors.orange
                : Colors.redAccent;

        // Truncate note to a single clean line
        String notePreview = '';
        if (item.note.isNotEmpty) {
          notePreview = item.note.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (notePreview.length > 40) {
            notePreview = '${notePreview.substring(0, 40)}…';
          }
        }

        final card = Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: progressColor.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isSelecting ? null : () => _showChecklistDetail(dark, key, item, done, total, progress, progressColor),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            backgroundColor: progressColor.withOpacity(0.15),
                            color: progressColor,
                            strokeWidth: 4,
                          ),
                          Text('$done/$total',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              item.matchkey.isNotEmpty ? item.matchkey : key,
                              style: GoogleFonts.museoModerno(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      dark ? Colors.white : Colors.black87),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _chip(
                                  item.alliance_color,
                                  item.alliance_color == 'Red'
                                      ? Colors.redAccent
                                      : Colors.blueAccent,
                                  dark),
                              if (item.returning_number > 0) ...[
                                const SizedBox(width: 6),
                                _chip('In: ${item.returning_number.toInt()}', Colors.blueGrey, dark),
                              ],
                              if (item.outgoing_number > 0) ...[
                                const SizedBox(width: 6),
                                _chip('Out: ${item.outgoing_number.toInt()}', Colors.teal, dark),
                              ],
                            ],
                          ),
                          if (notePreview.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(notePreview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: dark
                                        ? Colors.white38
                                        : Colors.black38)),
                          ],
                        ],
                      ),
                    ),
                    if (!_isSelecting)
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: dark ? Colors.white30 : Colors.black26),
                  ],
                ),
              ),
            ),
          ),
        );

        return _wrapCard(
            key, card, () => _deletePitCheckByKey(key), dark);
      },
    );
  }

  void _showChecklistDetail(bool dark, String key, PitChecklistItem item,
      int done, int total, double progress, Color progressColor) {
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white54 : Colors.black54;

    // Build subsystem status list
    bool drivetrainDone = item.drive_motors && item.drive_wheels &&
        item.drive_gearboxes && item.drive_wires && item.drive_nuts_and_bolts;
    bool structureDone = item.structure_frame && item.structure_hopper_panels &&
        item.structure_brain_pan && item.structure_belly_pan &&
        item.structure_nuts_and_bolts;
    bool intakeDone = item.intake_rack && item.intake_pinion &&
        item.intake_belts && item.intake_roller && item.intake_motors &&
        item.intake_nuts_and_bolts;
    bool spindexerDone = item.spindexer_panel && item.spindexer_churros &&
        item.spindexer_motor && item.spindexer_wheels &&
        item.spindexer_nuts_and_bolts;
    bool kickerDone = item.kicker_plates && item.kicker_roller &&
        item.kicker_belts && item.kicker_gears && item.kicker_motor &&
        item.kicker_nuts_and_bolts;
    bool shooterDone = item.shooter_flywheels && item.shooter_hood &&
        item.shooter_gears && item.shooter_motors &&
        item.shooter_nuts_and_bolts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          dark ? const Color.fromARGB(255, 25, 25, 25) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              backgroundColor: progressColor.withOpacity(0.15),
                              color: progressColor,
                              strokeWidth: 5,
                            ),
                            Text('$done/$total',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: progressColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.matchkey.isNotEmpty ? item.matchkey : key,
                          style: GoogleFonts.museoModerno(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        ),
                      ),
                      _chip(
                          item.alliance_color,
                          item.alliance_color == 'Red'
                              ? Colors.redAccent
                              : Colors.blueAccent,
                          dark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Battery Section
                  Text('Battery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _batteryDetailTile('Incoming', item.returning_number, item.returning_battery_voltage, Colors.blueGrey, dark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _batteryDetailTile('Outgoing', item.outgoing_number, item.outgoing_battery_voltage, Colors.teal, dark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subsystem Section
                  Text('Subsystems', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _checkSubsystem('Drivetrain', drivetrainDone, dark),
                      _checkSubsystem('Structure', structureDone, dark),
                      _checkSubsystem('Intake', intakeDone, dark),
                      _checkSubsystem('Spindexer', spindexerDone, dark),
                      _checkSubsystem('Kicker', kickerDone, dark),
                      _checkSubsystem('Shooter', shooterDone, dark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Notes Section
                  if (item.note.isNotEmpty) ...[
                    Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subColor)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: dark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: Text(item.note,
                          style: TextStyle(
                              fontSize: 14,
                              color: dark ? Colors.white70 : Colors.black87)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _batteryDetailTile(String label, double tag, double voltage, Color color, bool dark) {
    bool hasData = tag > 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasData
            ? color.withOpacity(0.1)
            : (dark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: hasData
                ? color.withOpacity(0.3)
                : (dark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasData ? color : (dark ? Colors.white38 : Colors.black38))),
          const SizedBox(height: 4),
          if (hasData)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tag ${tag.toInt()}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black87)),
                if (voltage > 0)
                  Text('${voltage.toStringAsFixed(1)}V',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black87)),
              ],
            )
          else
            Text('—',
                style: TextStyle(
                    fontSize: 14,
                    color: dark ? Colors.white24 : Colors.black26)),
        ],
      ),
    );
  }

  Widget _checkSubsystem(String name, bool done, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withOpacity(0.15)
            : (dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: done
                ? Colors.green.withOpacity(0.4)
                : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: done ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: done ? FontWeight.bold : FontWeight.normal,
                  color: done
                      ? (dark ? Colors.green.shade300 : Colors.green.shade700)
                      : (dark ? Colors.white54 : Colors.black45))),
        ],
      ),
    );
  }

  // ─── QUALITATIVE TAB ─────────────────────────────────────

  Widget _buildQualitativeTab(bool dark) {
    final entries = _qualRecords.entries.toList();
    final q = _searchQuery.toLowerCase();
    final filtered = q.isEmpty
        ? entries
        : entries.where((e) {
            final v = e.value;
            if (v is Map<String, dynamic>) {
              return (v['Scouter_Name']?.toString() ?? '')
                      .toLowerCase()
                      .contains(q) ||
                  (v['Match_Key']?.toString() ?? '')
                      .toLowerCase()
                      .contains(q) ||
                  (v['Alliance']?.toString() ?? '')
                      .toLowerCase()
                      .contains(q);
            }
            return e.key.toLowerCase().contains(q);
          }).toList();

    if (entries.isEmpty) {
      return _buildEmptyTab(dark, Icons.question_answer,
          'No Qualitative Logs', Colors.purple);
    }
    if (filtered.isEmpty) return _buildNoResults(dark);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final key = filtered[index].key;
        final raw = filtered[index].value;
        final cardBg =
            dark ? const Color.fromARGB(255, 22, 22, 22) : Colors.white;

        String scouter = '';
        String matchKey = key;
        String alliance = '';
        String q1 = '';
        String q2 = '';
        String q3 = '';
        String q4 = '';

        if (raw is Map<String, dynamic>) {
          scouter = raw['Scouter_Name']?.toString() ?? '';
          matchKey = raw['Match_Key']?.toString() ?? key;
          alliance = raw['Alliance']?.toString() ?? '';
          q1 = raw['Q1']?.toString() ?? '';
          q2 = raw['Q2']?.toString() ?? '';
          q3 = raw['Q3']?.toString() ?? '';
          q4 = raw['Q4']?.toString() ?? '';
        }

        final isRed = alliance == 'Red';
        final accent = isRed ? Colors.redAccent : Colors.purple;

        int answered = 0;
        if (q1.isNotEmpty) answered++;
        if (q2.isNotEmpty) answered++;
        if (q3.isNotEmpty) answered++;
        if (q4.isNotEmpty) answered++;

        final card = Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: accent.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isSelecting
                  ? null
                  : () => _showQualDetail(
                      dark, matchKey, scouter, alliance, q1, q2, q3, q4),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isRed
                              ? [Colors.red.shade700, Colors.red.shade400]
                              : [
                                  Colors.purple.shade700,
                                  Colors.purple.shade400
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.question_answer,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(matchKey,
                              style: GoogleFonts.museoModerno(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? Colors.white
                                      : Colors.black87),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Row(children: [
                            if (scouter.isNotEmpty) ...[
                              Icon(Icons.person_outline,
                                  size: 13,
                                  color: dark
                                      ? Colors.white54
                                      : Colors.black45),
                              const SizedBox(width: 4),
                              Text(scouter,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: dark
                                          ? Colors.white54
                                          : Colors.black45)),
                              const SizedBox(width: 8),
                            ],
                            if (alliance.isNotEmpty)
                              _chip(alliance, accent, dark),
                            const SizedBox(width: 6),
                            _chip('$answered/4 Q', Colors.teal, dark),
                          ]),
                        ],
                      ),
                    ),
                    if (!_isSelecting)
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: dark ? Colors.white30 : Colors.black26),
                  ],
                ),
              ),
            ),
          ),
        );

        return _wrapCard(key, card, () => _deleteQualByKey(key), dark);
      },
    );
  }

  void _showQualDetail(bool dark, String matchKey, String scouter,
      String alliance, String q1, String q2, String q3, String q4) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          dark ? const Color.fromARGB(255, 25, 25, 25) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final textColor = dark ? Colors.white : Colors.black87;
        final subColor = dark ? Colors.white54 : Colors.black54;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(matchKey,
                      style: GoogleFonts.museoModerno(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 4),
                  if (scouter.isNotEmpty)
                    Text('Scouted by $scouter',
                        style: TextStyle(fontSize: 14, color: subColor)),
                  const SizedBox(height: 16),
                  _qualAnswerTile('Q1', q1, dark),
                  _qualAnswerTile('Q2', q2, dark),
                  _qualAnswerTile('Q3', q3, dark),
                  _qualAnswerTile('Q4', q4, dark),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _qualAnswerTile(String label, String answer, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: dark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple)),
          const SizedBox(height: 4),
          Text(answer.isEmpty ? '—' : answer,
              style: TextStyle(
                  fontSize: 14,
                  color: dark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  // ─── Shared Widgets ──────────────────────────────────────

  Widget _chip(String label, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildNoResults(bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 50,
              color: dark ? Colors.white24 : Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No results found',
              style: GoogleFonts.museoModerno(
                  fontSize: 16,
                  color: dark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}
