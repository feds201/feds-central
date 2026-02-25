import 'package:flutter/material.dart';

class StarRating extends StatefulWidget {
  final int maxRating;
  final int initialRating;
  final double size;
  final Function(int rating) onRatingChanged;
  final Color activeColor;
  final Color inactiveColor;

  const StarRating({
    super.key,
    this.maxRating = 5,
    this.initialRating = 0,
    this.size = 70,
    required this.onRatingChanged,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentRating = index + 1;
            });
            widget.onRatingChanged(_currentRating);
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _currentRating == index + 1 ? 1.2 : 1.0,
            child: Icon(
              index < _currentRating
                  ? Icons.star
                  : Icons.star_border,
              color: index < _currentRating
                  ? widget.activeColor
                  : widget.inactiveColor,
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}
