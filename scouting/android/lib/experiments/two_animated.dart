import 'package:flutter/material.dart';

class TwoAnimatedBuilders extends StatefulWidget {
  final List<Listenable> animations;
  final Widget Function() builder;

  const TwoAnimatedBuilders({
    required this.animations,
    required this.builder,
  }) : super(key: const Key("TwoAnimatedBuilders"));

  @override
  _TwoAnimatedBuildersState createState() => _TwoAnimatedBuildersState();
}

class _TwoAnimatedBuildersState extends State<TwoAnimatedBuilders> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animations.first,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: widget.animations.last,
          builder: (context, _) {
            return widget.builder();
          },
        );
      },
    );
  }
}
