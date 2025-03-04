import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:math' as math;

import 'components/Chips.dart';
import 'components/nav.dart';
import 'components/plugin-tile.dart';
import 'home_page.dart';
import 'main.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.red, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
            child: Text(
              'About Us',
              style: GoogleFonts.museoModerno(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with Team Logo
            _buildHeroSection(context),

            // Team Journey Timeline
            _buildTeamJourneySection(),

            // Our Mission Section
            _buildMissionSection(),

            // Scout-Ops Development Story
            _buildScoutOpsStorySection(),

            // Team Achievements
            _buildAchievementsSection(),

            // Meet The Team
            _buildTeamMembersSection(),

            // Technologies Used
            _buildTechnologiesSection(),

            // Contact & Open Source
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.shade800, Colors.blue.shade800],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -50,
            top: -30,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                Icons.precision_manufacturing,
                size: 200,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Color.fromARGB(255, 255, 255, 255),
                  child: Image(
                      image: AssetImage('assets/logo.png'),
                      height: 90,
                      width: 90,
                      fit: BoxFit.fill),
                ),
                const SizedBox(height: 20),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'FEDS 201',
                      textStyle: GoogleFonts.orbitron(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      speed: const Duration(milliseconds: 200),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                const SizedBox(height: 10),
                Text(
                  "Falcon Engineering Design Solutions",
                  style: GoogleFonts.museoModerno(
                    fontSize: 16,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Rochester High School, Michigan",
                    style: GoogleFonts.museoModerno(
                      fontSize: 14,
                      color: Colors.white,
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

  Widget _buildTeamJourneySection() {
    final List<Map<String, dynamic>> timelineEvents = [
      {
        'year': '2007',
        'title': 'Team Founded',
        'description': 'FEDS 201 was established at Rochester High School',
        'icon': Icons.flag,
        'color': Colors.green,
      },
      {
        'year': '2018',
        'title': 'First Major Award',
        'description': 'Won the Engineering Excellence Award',
        'icon': Icons.emoji_events,
        'color': Colors.amber,
      },
      {
        'year': '2021',
        'title': 'Scout-Ops Concept',
        'description': 'Initial idea for a custom scouting solution',
        'icon': Icons.lightbulb,
        'color': Colors.orange,
      },
      {
        'year': '2023',
        'title': 'Scout-Ops Launch',
        'description': 'First competition using our custom scouting app',
        'icon': Icons.rocket_launch,
        'color': Colors.blue,
      },
      {
        'year': '2024',
        'title': 'Scout-Ops 2.0',
        'description': 'Major overhaul with new features and improvements',
        'icon': Icons.upgrade,
        'color': Colors.purple,
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                height: 25,
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.blue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Our Journey",
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: List.generate(
              timelineEvents.length,
              (index) => TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.2,
                isFirst: index == 0,
                isLast: index == timelineEvents.length - 1,
                indicatorStyle: IndicatorStyle(
                  width: 60,
                  height: 60,
                  indicator: Container(
                    decoration: BoxDecoration(
                      color: timelineEvents[index]['color'],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              timelineEvents[index]['color'].withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        timelineEvents[index]['icon'],
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                beforeLineStyle: LineStyle(
                  color: Colors.grey.shade300,
                  thickness: 3,
                ),
                endChild: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shadowColor:
                        timelineEvents[index]['color'].withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timelineEvents[index]['title'],
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: timelineEvents[index]['color'],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timelineEvents[index]['description'],
                            style: GoogleFonts.museoModerno(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                startChild: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: timelineEvents[index]['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      timelineEvents[index]['year'],
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: timelineEvents[index]['color'],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade800.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                Text(
                  "Our Mission",
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "At FEDS 201, we believe in empowering students through STEM education and real-world engineering challenges. Our mission is to foster innovation, teamwork, and leadership skills that prepare our members for future success.",
              style: GoogleFonts.museoModerno(
                fontSize: 16,
                height: 1.5,
                color: Colors.white,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMissionPillar(Icons.engineering, "Innovation"),
                _buildMissionPillar(Icons.groups, "Teamwork"),
                _buildMissionPillar(Icons.school, "Learning"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionPillar(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.museoModerno(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildScoutOpsStorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  height: 25,
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "The Scout-Ops Story",
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 8,
              shadowColor: Colors.purple.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.red, Colors.blue],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          "Scout-Ops",
                          style: GoogleFonts.orbitron(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Scout-Ops was born from a necessity. During competitions, our team faced challenges with data collection and analysis. We needed a solution that was fast, reliable, and specifically tailored to FRC scouting.",
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Development began in 2021 with a small team of student programmers. We aimed to create an app that would streamline the scouting process, provide real-time data analysis, and be user-friendly for all team members.",
                      style: TextStyle(
                          fontSize: 16, height: 1.5, color: Colors.black),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Through multiple iterations and testing during regional events, Scout-Ops evolved into a comprehensive scouting solution that has significantly improved our team's strategic decision-making process.",
                      style: TextStyle(
                          fontSize: 16, height: 1.5, color: Colors.black),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildFeatureBadge(
                              Icons.speed, "Fast Data Collection"),
                          _buildFeatureBadge(
                              Icons.qr_code_scanner, "QR Code Sharing"),
                          _buildFeatureBadge(
                              Icons.analytics, "Real-time Analytics"),
                          _buildFeatureBadge(Icons.widgets, "Modular Design"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade800, Colors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.museoModerno(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = [
      {
        'title': 'FIRST Impact Award',
        'description': 'Regional award at FIM State Championship',
        'year': '2024',
        'icon': Icons.military_tech,
      },
      {
        'title': 'Event Winner',
        'description': 'Bloomfield Girls Robotics Competition',
        'year': '2024',
        'icon': Icons.emoji_events,
      },
      {
        'title': 'District Event Winner',
        'description': 'Berrien Springs Event with FIRST Impact Award',
        'year': '2024',
        'icon': Icons.star,
      },
      {
        'title': 'Regional FIRST Impact Award',
        'description': 'Michigan State Championship',
        'year': '2023',
        'icon': Icons.military_tech,
      },
      {
        'title': 'District Championship Finalist',
        'description': 'APTIV Division',
        'year': '2023',
        'icon': Icons.workspace_premium,
      },
      {
        'title': 'Dean\'s List Finalist',
        'description': 'Anna Bochenek recognized for outstanding leadership',
        'year': '2022',
        'icon': Icons.school,
      },
      {
        'title': 'District Event Winner',
        'description': 'FIM District Lansing Event',
        'year': '2022',
        'icon': Icons.emoji_events,
      },
      {
        'title': 'Regional Chairman\'s Award',
        'description': 'FIRST\'s most prestigious team award',
        'year': '2021',
        'icon': Icons.military_tech,
      },
      {
        'title': 'Bloomfield Girls Competition Winner',
        'description': 'Supporting girls in STEM',
        'year': '2019',
        'icon': Icons.emoji_events,
      },
      {
        'title': 'Division Finalist',
        'description': 'Archimedes Division',
        'year': '2003',
        'icon': Icons.workspace_premium,
      },
      {
        'title': 'Regional Winner',
        'description': 'Buckeye Regional',
        'year': '2002',
        'icon': Icons.emoji_events,
      },
      {
        'title': 'Engineering Excellence',
        'description': 'Autodesk Excellence in Engineering',
        'year': '2000',
        'icon': Icons.build,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 25,
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Team Achievements",
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 15),
                  child: Card(
                    elevation: 5,
                    shadowColor: Colors.amber.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade700,
                            Colors.amber.shade400,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    achievements[index]['icon'] as IconData,
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    achievements[index]['year'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              achievements[index]['title'] as String,
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              achievements[index]['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersSection() {
    // Example team roles - replace with actual roles from your team
    final teamRoles = [
      {
        'role': 'Programming',
        'description': 'Development of robot code and Scout-Ops application',
        'icon': Icons.code,
        'color': Colors.blue,
      },
      {
        'role': 'Mechanical',
        'description': 'Design and fabrication of robot components',
        'icon': Icons.build,
        'color': Colors.orange,
      },
      {
        'role': 'Electrical',
        'description': 'Wiring, electronics, and power systems',
        'icon': Icons.bolt,
        'color': Colors.yellow,
      },
      {
        'role': 'Strategy',
        'description': 'Game analysis and competition planning',
        'icon': Icons.auto_graph,
        'color': Colors.green,
      },
      {
        'role': 'Outreach',
        'description': 'Community engagement and sponsor relations',
        'icon': Icons.people,
        'color': Colors.purple,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  height: 25,
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.teal],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Meet The Team",
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "FEDS 201 is composed of dedicated students and mentors who contribute their unique skills across various disciplines. Our diversity in talents and passion for robotics drive our success.",
              style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: teamRoles.length,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                return Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 15),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            teamRoles[index]['icon'] as IconData,
                            size: 40,
                            color: teamRoles[index]['color'] as Color,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            teamRoles[index]['role'] as String,
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: teamRoles[index]['color'] as Color,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            teamRoles[index]['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isdarkmode()
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnologiesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                height: 25,
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.green],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Technologies Used",
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Scout-Ops is built with modern technologies to ensure reliability, performance, and a great user experience:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  buildChip("Flutter", [Colors.blue, Colors.blueAccent], false),
                  buildChip(
                      "Google Fonts", [Colors.red, Colors.redAccent], false),
                  buildChip("Material Icons",
                      [Colors.green, Colors.greenAccent], false),
                  buildChip(
                      "Dart", [Colors.purple, Colors.purpleAccent], false),
                  buildChip("Android Studio", [Colors.teal, Colors.tealAccent],
                      false),
                  buildChip("GitHub",
                      [Colors.grey.shade800, Colors.grey.shade600], false),
                  buildChip(
                      "Provider", [Colors.orange, Colors.orangeAccent], false),
                  buildChip(
                      "http", [Colors.brown, Colors.brown.shade300], false),
                  buildChip(
                      "Hive", [Colors.yellow, Colors.yellowAccent], false),
                  buildChip("The Blue Alliance",
                      [Colors.blue, Colors.blueAccent], false),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "We are always looking to improve and expand our technology stack. If you have suggestions or want to contribute, feel free to reach out!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Open GitHub repository
                    launchUrl(
                        Uri.parse("https://github.com/your-repo-url-here"));
                  },
                  child: Text("View on GitHub"),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Open The Blue Alliance
                    launchUrl(Uri.parse("https://www.thebluealliance.com/"));
                  },
                  child: Text("Visit The Blue Alliance"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                height: 25,
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.red.shade900],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Connect With Us",
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade800, Colors.redAccent.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade900.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mail, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      "Get In Touch",
                      style: GoogleFonts.orbitron(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Have questions about Scout-Ops or interested in adapting it for your team? We're happy to help!",
                  style: GoogleFonts.museoModerno(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Contact Methods
                _buildContactMethod(
                    Icons.email, "Email Us", "feds201@google.com"),
                _buildContactMethod(
                    Icons.language, "Team Website", "https://www.feds201.com"),
                _buildContactMethod(Icons.location_on, "Visit Us",
                    "Rochester High School, 180 S Livernois Rd, Rochester Hills, MI 48307"),

                const SizedBox(height: 25),

                // Social Media Section
                Center(
                  child: Text(
                    "Follow Us",
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Social Media Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(Icons.facebook, Colors.blue.shade700),
                    const SizedBox(width: 16),
                    _buildSocialButton(Icons.web, Colors.teal),
                    const SizedBox(width: 16),
                    _buildSocialButton(Icons.photo_camera, Colors.purple),
                    const SizedBox(width: 16),
                    _buildSocialButton(Icons.video_library, Colors.red),
                  ],
                ),

                const SizedBox(height: 30),

                // Open Source Contribution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Open Source Project",
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Scout-Ops is an open source project. We welcome contributions from the FIRST community. Join us in making scouting better for everyone!",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.code_rounded,
                              color: Colors.red.shade800),
                          label: Text("Contribute on GitHub",
                              style: TextStyle(color: Colors.red.shade800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () {
                            launchUrl(Uri.parse(
                                "https://github.com/FEDS201-Scout-Ops"));
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Copyright & Credits
                Center(
                  child: Text(
                    "© ${DateTime.now().year} FEDS 201 Robotics Team",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "Made with ❤️ in Michigan",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactMethod(IconData icon, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.museoModerno(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Add specific URLs for each social platform
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
