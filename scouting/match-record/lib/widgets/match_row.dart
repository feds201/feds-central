import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';

class MatchRow extends StatelessWidget {
  final MatchWithVideos matchWithVideos;
  final int? yourTeamNumber;
  final Set<int>? highlightTeamNumbers;
  final bool showEventLabel;
  final VoidCallback? onTap;

  const MatchRow({
    super.key,
    required this.matchWithVideos,
    this.yourTeamNumber,
    this.highlightTeamNumbers,
    this.showEventLabel = false,
    this.onTap,
  });

  String _formatTime(int? unixSeconds) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = matchWithVideos.match;
    final played = m.redScore >= 0 && m.blueScore >= 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
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
                  if (m.time != null)
                    Text(
                      _formatTime(m.time),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                  ),
                  const SizedBox(height: 2),
                  _buildAllianceRow(
                    context,
                    teamKeys: m.blueTeamKeys,
                    score: m.blueScore,
                    color: Colors.blue.shade300,
                    isWinner: m.winningAlliance == 'blue',
                    played: played,
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
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
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
    final icons = <Widget>[];

    if (matchWithVideos.hasYouTube) {
      icons.add(IconButton(
        icon: const Icon(Icons.play_circle_outline, size: 20),
        tooltip: 'YouTube',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        onPressed: () {
          final key = matchWithVideos.match.youtubeKey!;
          final url = Uri.parse('https://www.youtube.com/watch?v=$key');
          launchUrl(url, mode: LaunchMode.externalApplication);
        },
      ));
    }

    if (matchWithVideos.hasRecordings) {
      icons.add(const Padding(
        padding: EdgeInsets.only(left: 2),
        child: Icon(Icons.videocam, size: 18),
      ));
    }

    if (matchWithVideos.hasLocalRippedVideo) {
      icons.add(const Padding(
        padding: EdgeInsets.only(left: 2),
        child: Icon(Icons.movie, size: 18),
      ));
    }

    if (icons.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}
