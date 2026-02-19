import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget ShowInsiration() {
  return Card(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    elevation: 6,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Every Second Inspiration',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            getRandomScoutingTip(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

String getRandomScoutingTip() {
  List<String> tips = [
    "Focus on one robot at a time to get accurate data.",
    "Note unusual strategies that might affect alliance selection.",
    "Watch for consistent performance rather than best/worst matches.",
    "Pay attention to robot speed and maneuverability during matches.",
    "Defense capability can be just as valuable as scoring ability.",
    "Track cycle times for repetitive actions to gauge efficiency.",
    "Note any technical issues that might indicate reliability problems.",
    "Watch for effective communication between alliance partners.",
    "Be aware of the field layout and how it affects robot movement.",
    "Take note of any unique features or strategies used by teams.",
    "Scouting is only as hard as you make it. You can always give up. 😁",
    "Data drives decisions—scout smart, strategize smarter.",
    "Scouting isn't just collecting numbers; it's unlocking victories.",
    "Great teams don't guess—they scout.",
    "Every match tells a story. It's your job to read it.",
    "Championships are built on good scouting.",
    "Scouting today wins matches tomorrow.",
    "Your data is your weapon—use it wisely.",
    "Precision in scouting leads to domination on the field.",
    "The best alliances are chosen, not given.",
    "To defeat the ops, you must scout them using Scout Ops.",
    "Numbers don't lie—trust the data, trust the process.",
    "If this app breaks, it's your fault not ours",
    "Agents, remember a goup of spies is always better then a hivemind",
    "Every match you scout is a step closer to seeing your strategy come to life.",
    "The robots may be on the field, but the future is in your notes.",
    "A great match starts with great data; your observations lay the foundation for victory.",
    "The more you know, the better you grow. Scout with precision, compete with confidence.",
    "Behind every winning strategy is a team that never stopped analyzing.",
    "Scouting isn’t just about watching robots, it’s about understanding the rhythm of the game.",
    "Success in FRC is built on the small moments captured in your scouting sheets.",
    "In scouting, every detail matters — it’s the difference between a good match and a great one.",
    "When you see the game clearly, you can outthink the competition.",
    "Scouting is the quiet hero of every FRC match — it's the knowledge that wins the battle.",
    "Every match you scout is a step closer to seeing your strategy come to life.",
    "The robots may be on the field, but the future is in your notes.",
    "A great match starts with great data; your observations lay the foundation for victory.",
    "The more you know, the better you grow. Scout with precision, compete with confidence.",
    "Behind every winning strategy is a team that never stopped analyzing.",
    "Scouting isn’t just about watching robots, it’s about understanding the rhythm of the game.",
    "Success in FRC is built on the small moments captured in your scouting sheets.",
    "In scouting, every detail matters — it’s the difference between a good match and a great one.",
    "When you see the game clearly, you can outthink the competition.",
    "Scouting is the quiet hero of every FRC match — it's the knowledge that wins the battle.",
    "Follow our lord and savior, Ritesh Raj, for a scouting advantage",
    "Just like the beat of Dandanakka, Ritesh Raj Arul Selvan’s app brings the rhythm to your scouting, making every match easier to analyze and every strategy stronger!",
    "In the rhythm of scouting, we don’t just follow the beat; we create it—just like Dandanakka!",
    "Just like Dandanakka’s catchy beat, every piece of scouting data adds to the flow that leads to victory!",
    "When the competition feels overwhelming, remember: keep the tempo steady, just like Dandanakka, and success will follow.",
    "Every match you scout adds a layer to your strategy, just like the layers of rhythm in Dandanakka—steady, strong, and unstoppable.",
    "Just as Dandanakka captures your attention, the details in every match you scout will grab your team's focus and lead them to greatness.",
    "Keep your scouting as sharp as Dandanakka’s beat, and you’ll compose a strategy that moves with power and precision!",
    "In the Reefscape, your scouting knowledge is the bassline that keeps the strategy in sync, just like Dandanakka keeps the crowd moving.",
    "Like the infectious groove of Dandanakka, your scouting energy fuels the team's drive to perform with confidence.",
    "As Dandanakka's rhythm builds to a crescendo, your insights will shape a strategy that rises above the competition.",
    "The best teams in Reefscape move with precision—just like the rhythm of Dandanakka, they know when to strike and when to adapt.",
    "In the Reefscape, every team is a unique species—scouting helps you understand their strengths and weaknesses.",
    "Scouting is like mapping the ocean’s currents; the more you understand, the smoother your journey to victory.",
    "A healthy reef thrives on diversity—your scouting insights bring together the unique strengths of every team.",
    "In the depths of competition, your scouting knowledge is the lighthouse guiding your team toward success.",
    "Just as a reef is built by countless tiny pieces, a winning strategy is formed from the details you discover through scouting.",
    "Like coral in a reef, each match provides another layer of insight to strengthen your team's foundation.",
    "Dive deep into the data—every match is an opportunity to uncover the hidden treasures of strategy.",
    "In the Reefscape, the best teams don’t just survive—they adapt and thrive by learning from every match.",
    "The ocean of competition is vast, but your scouting maps the best path to victory.",
  ];

  return tips[DateTime.now().microsecond % tips.length];
}
