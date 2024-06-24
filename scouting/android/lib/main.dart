// ignore_for_file: prefer_const_constructors
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';

const Color themeColor = Color.fromARGB(255, 255, 255, 255);
const bool material3 = true;

final WidgetStateProperty<Icon?> thumbIcon =
    WidgetStateProperty.resolveWith<Icon?>(
  (Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return const Icon(Icons.check);
    }
    return const Icon(Icons.close);
  },
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scouting App 2024',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        useMaterial3: material3,
      ),
      home: const HomePage(),
    );
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 250,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView(
        padding: const EdgeInsets.all(0),
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              color: Color.fromARGB(255, 51, 109, 216),
            ),
            child: Column(
              // Use a Column to arrange heading and description vertically
              children: [
                Text(
                  'FEDS 2024', // Heading
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ), // Removed italic for a stronger heading
                ),
                SizedBox(
                    height: 1), // Add spacing between heading and description
                Text(
                  'Scouting App', // Description
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16, // Reduced font size for description
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Home'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            selectedColor: const Color.fromARGB(255, 0, 55, 173),
            onTap: () {
              Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => const HomePage()),
                  MaterialPageRoute(builder: (context) => const HomePage()));
            },
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('Match'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MatchPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('Settings'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 5),
          ListTile(
            title: const Text('About'),
            tileColor: const Color.fromARGB(255, 185, 206, 252),
            minVerticalPadding: 20,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 158, 158),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Welcome to the FRC FEDS Team Scouting App, your all-in-one companion for the ultimate robotics scouting experience. Designed by and for enthusiasts of the FIRST Robotics Competition, our app empowers teams with real-time data and insights to strategize effectively during competitions. From tracking robot performance and match outcomes to analyzing opponent strengths, our intuitive interface ensures that every decision on the field is backed by comprehensive scouting intelligence. Join us in revolutionizing how teams compete and collaborate in the thrilling world of FRC.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 5, 5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Welcome to the Scouting App 2024!',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                margin: EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 238, 106, 106),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Welcome to the Scouting App 2024!',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Match'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: const Center(
        child: Text('Match Page'),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: const Center(
        child: Text('About Page'),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Color.fromARGB(255, 241, 255, 241),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: EdgeInsets.only(left: 10, right: 10,),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 241, 255, 241),
              ),
            child: TextField(
              decoration: InputDecoration(
                labelText:
                    "Client Name", // Text label displayed above the field
                filled: true, // Fills the container with background color
                fillColor: Colors
                    .grey[200], // Light gray fill color (Material 3 style)
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 15, vertical: 10), // Padding around the text
                border: OutlineInputBorder(
                  // Outlined border style
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
              ),
            ),
            ),
            SwitchListTile(
              tileColor: Color.fromARGB(255, 241, 255, 241),
              contentPadding: EdgeInsets.only(left: 10, right: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              title: Text("Active"), // Add your desired text
              value: true,
              onChanged: (bool value) {
                // ... your logic here
              },
              activeTrackColor: Color.fromARGB(255, 11, 243, 11),
              activeColor: Color.fromARGB(
                  255, 255, 255, 255), // Green color for active state
            ),
            Container(
              padding: const EdgeInsets.all(10),
              margin: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 5),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 241, 255, 241),
              ),

              child: ListView.builder(




              )
              )
          ],
        ),
      ),
    );
  }
}

void getBluetoothDevices() async {
  // Get the Bluetooth adapter
  final adapter = await FlutterBlue.instance.adapter;

  // Start scanning for devices
  adapter.startScan();

  // Listen for discovered devices
  adapter.onScanResult.listen((result) {
    // Print the device name and address
    print('Device found: ${result.device.name} ${result.device.id}');
  });
}
