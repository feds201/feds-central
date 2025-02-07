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

  const PluginTile({super.key, 
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
    return InkWell(
        onTap: () => onTap_Widget(),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
        highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading:
                    Icon(icon_Widget, color: Theme.of(context).primaryColor),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Switch(
                  value: value_trailing,
                  onChanged: enabled_trailing ? onToggle_Trailing : null,
                  activeColor: enabled_trailing
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                ),
              ),
              if (expanded_Widget)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Expanded_Widget,
                ),
            ],
          ),
        ));
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
    return InkWell(
      onTap: () => onTap_Widget(),
      splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
      highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              leading: icon_Widget,
              title: gradient != null
                  ? ShaderMask(
                      shaderCallback: (bounds) =>
                          gradient!.createShader(bounds),
                      child: title,
                    )
                  : title,
            ),
            if (expanded_Widget)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Expanded_Widget,
              ),
          ],
        ),
      ),
    );
  }
}
