import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void DefaultonRatingUpdate(double rating) {
  print(rating);
}

Widget buildRating(String title, IconData icon, double rating, int maxRating, Color internaryColor, {Function(double)? onRatingUpdate = DefaultonRatingUpdate}) {
  return Column(
    children: [
      Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
      const SizedBox(height: 8),
      Center(
        child: RatingBar.builder(
          initialRating: rating.toDouble(),
          minRating: 0,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: maxRating,
          glow: true,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(
            Icons.star,
            color: internaryColor,
          ),
          onRatingUpdate: (rating) {
            onRatingUpdate!(rating);
          },
        ),
      ),
    ],
  );
}