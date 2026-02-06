import 'package:flutter/material.dart';

Widget buildPhaseSele(
  BuildContext context,
  Function(int shift) onclick,
  int selectedShift, // Pass the currently selected index (0-4)
) {
  // Helper function to create the styled buttons
  Widget buildPhaseButton({
    required String label,
    required int id,
    required Color baseColor,
    double fontSize = 20,
  }) {
    final bool isSelected = selectedShift == id;
    final Color textColor = const Color(0xFF2A2A2A);

    return Expanded(
      child: GestureDetector(
        onTap: () => onclick(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(6), // Spacing between buttons
          decoration: BoxDecoration(
            // Soft, rounded tile with subtle depth
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [baseColor.withOpacity(1.0), baseColor.withOpacity(0.75)]
                  : [baseColor.withOpacity(0.9), baseColor.withOpacity(0.65)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: baseColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(-2, -2),
              ),
              if (isSelected)
                BoxShadow(
                  color: baseColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.65),
                    fontFamily: 'MuseoModerno',
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Row(
              children: const [
                Icon(
                  Icons.view_in_ar,
                  size: 18,
                  color: Colors.white70,
                ),
                SizedBox(width: 8),
                Text(
                  "Phase Selection",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT COLUMN: The Tall "Transition" Button
                Expanded(
                  flex: 3, // Takes ~30% width
                  child: buildPhaseButton(
                    label: "T",
                    id: 0,
                    baseColor: const Color(0xFFE0643B),
                    fontSize: 52,
                  ),
                ),

                // RIGHT COLUMN: The 2x2 Grid
                Expanded(
                  flex: 7, // Takes ~70% width
                  child: Column(
                    children: [
                      // TOP ROW
                      Expanded(
                        child: Row(
                          children: [
                            buildPhaseButton(
                              label: "1",
                              id: 1,
                              baseColor: const Color(0xFF57E62E),
                              fontSize: 40,
                            ),
                            buildPhaseButton(
                              label: "2",
                              id: 2,
                              baseColor: const Color(0xFF4C6D3A),
                              fontSize: 40,
                            ),
                          ],
                        ),
                      ),
                      // BOTTOM ROW
                      Expanded(
                        child: Row(
                          children: [
                            buildPhaseButton(
                              label: "1",
                              id: 3,
                              baseColor: const Color(0xFFE9B86A),
                              fontSize: 40,
                            ),
                            buildPhaseButton(
                              label: "2",
                              id: 4,
                              baseColor: const Color(0xFFE0B15D),
                              fontSize: 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
