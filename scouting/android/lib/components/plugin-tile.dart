import 'package:flutter/material.dart';

class PluginTile extends StatelessWidget {
  final String title;
  final String description;
  final Function onTap_Widget;
  final IconData icon_Widget;
  final bool expanded_Widget;
  final bool value_trailing;
  final bool enabled_trailing;
  final Function(bool) onToggle_Trailing;
  final Widget Expanded_Widget;

  const PluginTile({
    super.key,
    required this.title,
    required this.description,
    required this.onTap_Widget,
    required this.icon_Widget,
    required this.expanded_Widget,
    required this.value_trailing,
    this.enabled_trailing = true,
    required this.onToggle_Trailing,
    required this.Expanded_Widget,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap_Widget(),
            splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
            highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tile header
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                  child: Row(
                    children: [
                      // Icon with background
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon_Widget,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Title and description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Switch with custom styling
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: value_trailing,
                          onChanged:
                              enabled_trailing ? onToggle_Trailing : null,
                          activeColor: Colors.white,
                          activeTrackColor: enabled_trailing
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expandable content
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstChild: Container(height: 0),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Expanded_Widget,
                  ),
                  crossFadeState: expanded_Widget
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExpandableTile extends StatelessWidget {
  final Widget title;
  final Function onTap_Widget;
  final Widget icon_Widget;
  final bool expanded_Widget;
  final Widget Expanded_Widget;
  final Color? color;
  final LinearGradient? gradient;

  const ExpandableTile({
    super.key,
    required this.title,
    required this.onTap_Widget,
    required this.icon_Widget,
    required this.expanded_Widget,
    required this.Expanded_Widget,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (gradient != null)
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap_Widget(),
            splashColor: (gradient != null)
                ? Colors.white.withOpacity(0.2)
                : Theme.of(context).primaryColor.withOpacity(0.2),
            highlightColor: (gradient != null)
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with expanded indicator
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon with custom styling based on gradient presence
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (gradient != null)
                              ? Colors.white.withOpacity(0.2)
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: icon_Widget,
                      ),
                      const SizedBox(width: 16),
                      // Title
                      Expanded(
                        child: gradient != null
                            ? ShaderMask(
                                shaderCallback: (bounds) =>
                                    gradient!.createShader(bounds),
                                child: title,
                              )
                            : title,
                      ),
                    ],
                  ),
                ),
                // Expandable content
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstChild: Container(height: 0),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Expanded_Widget,
                  ),
                  crossFadeState: expanded_Widget
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
