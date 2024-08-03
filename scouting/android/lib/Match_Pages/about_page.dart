
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/nav.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('About Page'),
            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    var status = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return status.values.every((status) => status.isGranted);
  }
}
