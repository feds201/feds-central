import 'package:flutter/material.dart';

enum SearchChipType { team, alliance }

class SearchChip {
  final SearchChipType type;
  final String label;
  final int? teamNumber;
  final List<String>? alliancePicks;

  const SearchChip.team(this.teamNumber, this.label)
      : type = SearchChipType.team,
        alliancePicks = null;

  const SearchChip.alliance(this.label, this.alliancePicks)
      : type = SearchChipType.alliance,
        teamNumber = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchChip &&
          type == other.type &&
          label == other.label &&
          teamNumber == other.teamNumber;

  @override
  int get hashCode => Object.hash(type, label, teamNumber);
}

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final List<SearchChip> chips;
  final FocusNode focusNode;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<SearchChip> onChipRemoved;
  final VoidCallback? onSubmitted;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.chips,
    required this.focusNode,
    required this.onTextChanged,
    required this.onChipRemoved,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final chip in chips)
                  InputChip(
                    label: Text(chip.label),
                    onDeleted: () => onChipRemoved(chip),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      chip.type == SearchChipType.team
                          ? Icons.person
                          : Icons.groups,
                      size: 16,
                    ),
                  ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 150),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: onTextChanged,
                      onSubmitted: (_) => onSubmitted?.call(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
