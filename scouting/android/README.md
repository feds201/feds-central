# ScoutOps

ScoutOps is a mobile-friendly and UI-friendly scouting application designed for FRC matches. Originally intended for use by a single team, ScoutOps is now open for public use, allowing users to recreate and grow the app as a community. If you use this app, please mention the creator.

## General Information

- **Name:** ScoutOps
- **Primary Purpose:** To provide a mobile and user-friendly way to scout and record FRC match data.
- **Intended Users:** Initially designed for a single team, now open for public use.
- **Platforms Supported:** Android (Mobile), with ongoing extensions for Raspberry Pi and Windows/Linux computers to host a local area database for immediate data transfer. A Windows ScoutData management app is also in progress.

## Features and Functionality

- **Main Features:**
  - User-friendly UI.
  - Plugin support for custom functionality.

- **Data Collection and Storage:**
  - Uses Hive for storage.
  - Standard variable storing.

- **Data Synchronization:**
  - Utilizes Bluetooth PAN to connect up to 8 devices (standard Windows OS limitation).

- **Offline Functionality:**
  - Before an event, navigate to Settings > Load Match and enter the upcoming event key to download and store match data locally.

## Technical Details

- **Technologies and Frameworks Used:**
  - Built with Flutter for Android.

- **Bluetooth PAN for Data Transfer:**
  - Creates a Bluetooth PAN using Windows Bluetooth hotspot.

- **Main Components:**
  - Hive
  - TheBlueAlliance API
  - MaterialUI

- **Third-Party Services and APIs:**
  - TheBlueAlliance API
  - Generic Networking API

## Setup and Usage

### Prerequisites

- Download the app and start using it. Note that the Template Creator section and Pit data recorder are not active yet.

### Installation and Configuration

1. Click on the 3 navigation bar.
2. Click on Settings.
3. Enter the Scouter Name.
4. Give permission for Location, Bluetooth, and Nearby Devices.
5. To save a local version of a match, click on Load Match and enter the event key. If the circle turns green, the match has been successfully downloaded, and the app is ready to scout the match completely without internet.

### Starting the App

- Click on the app icon to open it.

## Maintenance and Support

### Known Issues and Limitations

- Does not have Pit data recorder and templating features.

### Reporting Bugs and Requesting Features

- Report bugs and request new features by raising an issue on GitHub.

### Future Plans

- There are many planned updates and enhancements.

  ### App Pictures
  
