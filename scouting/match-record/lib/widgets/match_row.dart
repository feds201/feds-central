import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';

class MatchRow extends StatelessWidget {
  final MatchWithVideos matchWithVideos;
  final int? yourTeamNumber;
  final Set<int>? highlightTeamNumbers;
  final bool showEventLabel;
  final bool isYourMatch;
  final List<Alliance> alliances;
  final VoidCallback? onTap;

  const MatchRow({
    super.key,
    required this.matchWithVideos,
    this.yourTeamNumber,
    this.highlightTeamNumbers,
    this.showEventLabel = false,
    this.isYourMatch = false,
    this.alliances = const [],
    this.onTap,
  });

  static String formatTime(int? unixSeconds) {
    if (unixSeconds == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = weekdays[dt.weekday - 1];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $hour:$minute $amPm';
  }

  /// Whether scheduled time should show with strikethrough + predicted time.
  /// True when: no actualTime, predictedTime exists, and predicted differs
  /// from scheduled by more than 60 seconds.
  static bool shouldShowDelayedTime(Match m) {
    if (m.actualTime != null) return false;
    if (m.predictedTime == null || m.time == null) return false;
    return (m.predictedTime! - m.time!).abs() > 60;
  }

  String _stripFrc(String key) => key.replaceFirst('frc', '');

  bool _shouldBold(String teamKey) {
    final num = int.tryParse(_stripFrc(teamKey));
    if (num == null) return false;
    if (yourTeamNumber != null && num == yourTeamNumber) return true;
    if (highlightTeamNumbers != null && highlightTeamNumbers!.contains(num)) {
      return true;
    }
    return false;
  }

  /// Find the alliance label (e.g. "A1") for a set of team keys in a playoff match.
  String? _findAllianceLabel(List<String> teamKeys) {
    if (matchWithVideos.match.compLevel == 'qm') return null;
    if (alliances.isEmpty) return null;
    final teamKeySet = teamKeys.toSet();
    for (final alliance in alliances) {
      if (alliance.eventKey != matchWithVideos.match.eventKey) continue;
      // Check if any of the alliance picks are in this match's team keys
      if (alliance.picks.any((pick) => teamKeySet.contains(pick))) {
        return 'A${alliance.allianceNumber}';
      }
    }
    return null;
  }

  Widget _buildTimeDisplay(BuildContext context, Match m) {
    final theme = Theme.of(context);
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (shouldShowDelayedTime(m)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatTime(m.time),
            style: timeStyle?.copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            formatTime(m.predictedTime),
            style: timeStyle,
          ),
        ],
      );
    }

    final displayTime = m.bestTime;
    if (displayTime == null) return const SizedBox.shrink();
    return Text(formatTime(displayTime), style: timeStyle);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = matchWithVideos.match;
    final played = m.redScore >= 0 && m.blueScore >= 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: isYourMatch
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Match identifier + time
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.displayName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  _buildTimeDisplay(context, m),
                  if (showEventLabel && matchWithVideos.eventShortName != null)
                    Text(
                      matchWithVideos.eventShortName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Teams + scores
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAllianceRow(
                    context,
                    teamKeys: m.redTeamKeys,
                    score: m.redScore,
                    color: Colors.red.shade300,
                    isWinner: m.winningAlliance == 'red',
                    played: played,
                    allianceLabel: _findAllianceLabel(m.redTeamKeys),
                  ),
                  const SizedBox(height: 2),
                  _buildAllianceRow(
                    context,
                    teamKeys: m.blueTeamKeys,
                    score: m.blueScore,
                    color: Colors.blue.shade300,
                    isWinner: m.winningAlliance == 'blue',
                    played: played,
                    allianceLabel: _findAllianceLabel(m.blueTeamKeys),
                  ),
                ],
              ),
            ),
            // Video icons
            _buildVideoIcons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAllianceRow(
    BuildContext context, {
    required List<String> teamKeys,
    required int score,
    required Color color,
    required bool isWinner,
    required bool played,
    String? allianceLabel,
  }) {
    final theme = Theme.of(context);

    final teamSpans = <InlineSpan>[];
    for (var i = 0; i < teamKeys.length; i++) {
      if (i > 0) {
        teamSpans.add(TextSpan(
          text: ' \u00b7 ',
          style: TextStyle(color: color),
        ));
      }
      final bold = _shouldBold(teamKeys[i]);
      teamSpans.add(TextSpan(
        text: _stripFrc(teamKeys[i]),
        style: TextStyle(
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          decoration: bold ? TextDecoration.underline : null,
          decorationColor: bold ? color : null,
        ),
      ));
    }

    // m5: Show alliance label after team names for playoff matches
    if (allianceLabel != null) {
      teamSpans.add(TextSpan(
        text: ' \u00b7 ($allianceLabel)',
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
      ));
    }

    final scoreText = played ? '$score' : '\u2014';
    final scoreWeight =
        played && isWinner ? FontWeight.bold : FontWeight.normal;

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(children: teamSpans),
            style: theme.textTheme.bodySmall,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            scoreText,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: scoreWeight,
              color: played ? color : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoIcons(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Score indicator
        if (matchWithVideos.match.redScore >= 0 && matchWithVideos.match.blueScore >= 0)
          const SizedBox.shrink()
        else
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '-',
              style: theme.textTheme.bodySmall?.copyWith(color: disabledColor),
            ),
          ),
        // YouTube icon
        if (matchWithVideos.hasYouTube)
          IconButton(
            icon: const Icon(Icons.play_circle_outline, size: 20),
            tooltip: 'YouTube',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              final key = matchWithVideos.match.youtubeKey!;
              final url = Uri.parse('https://www.youtube.com/watch?v=$key');
              launchUrl(url, mode: LaunchMode.externalApplication);
            },
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(Icons.play_circle_outline, size: 20, color: disabledColor),
          ),
        // Local recording icon
        if (matchWithVideos.hasRecordings)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.videocam, size: 18),
          )
        else
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(Icons.videocam_off, size: 18, color: disabledColor),
          ),
        // Local ripped video icon
        if (matchWithVideos.hasLocalRippedVideo)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.movie, size: 18),
          ),
      ],
    );
  }
}
