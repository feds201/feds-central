# 🚀 ScoutOps

ScoutOps is a mobile-friendly and UI-friendly scouting application designed for FRC matches. Originally intended for use by a single team, ScoutOps is now open for public use, allowing users to recreate and grow the app as a community. If you use this app, please mention the creator. 😊

## 🔍 General Information

- **Name:** ScoutOps
- **Primary Purpose:** To provide a mobile and user-friendly way to scout and record FRC match data.
- **Intended Users:** Initially designed for a single team, now open for public use.
- **Platforms Supported:** Android 📱 (Mobile), with ongoing extensions for Raspberry Pi 🥧 and Windows/Linux computers 🖥️ to host a local area database for immediate data transfer. A Windows ScoutData management app is also in progress.

## ✨ Features and Functionality

- **Main Features:**
  - User-friendly UI. 😍
  - Plugin support for custom functionality. 🔌

- **Data Collection and Storage:**
  - Uses Hive for storage. 🐝
  - Standard variable storing. 📦

- **Data Synchronization:**
  - Utilizes Bluetooth PAN to connect up to 8 devices (standard Windows OS limitation). 🔗

- **Offline Functionality:**
  - Before an event, navigate to Settings > Load Match and enter the upcoming event key to download and store match data locally. 📥

## 🛠️ Technical Details

- **Technologies and Frameworks Used:**
  - Built with Flutter for Android. 🐦

- **Bluetooth PAN for Data Transfer:**
  - Creates a Bluetooth PAN using Windows Bluetooth hotspot. 🔄

- **Main Components:**
  - Hive 🐝
  - TheBlueAlliance API 🌐
  - MaterialUI 🎨

- **Third-Party Services and APIs:**
  - TheBlueAlliance API 🌐
  - Generic Networking API 📡

## 🚀 Setup and Usage

### 📋 Prerequisites

- Download the app and start using it. Note that the Template Creator section and Pit data recorder are not active yet.

### 📥 Installation and Configuration

1. Click on the 3 navigation bars ☰.
2. Click on Settings ⚙️.
3. Enter the Scouter Name 🕵️.
4. Give permission for Location 📍, Bluetooth 🔵, and Nearby Devices 📶.
5. To save a local version of a Event, click on Load Match and enter the event key. If the circle turns green, the match has been successfully downloaded, and the app is ready to scout the match completely without internet. 🌐

### 🚀 Starting the App

- Click on the app icon to open it. 📲

## 🛠️ Maintenance and Support

### 🐛 Known Issues and Limitations

- Does not have Pit data recorder and templating features.

### 📬 Reporting Bugs and Requesting Features

- Report bugs and request new features by raising an issue on GitHub.

### 🔮 Future Plans

- There are many planned updates and enhancements.

## 📸 App Pictures

| Description | Image |
| ----------- | ----- |
| Click on Start Match to get started. | <img src="https://github.com/user-attachments/assets/0c4c653e-32fb-4f0f-8af8-c00bcfac009b" alt="Start Match" width="200"/> |
| This is the Match Selection Page. Fill in the details and go to the Match Tab for selection. | <img src="https://github.com/user-attachments/assets/11fbbf03-fb66-4d8e-99ac-bcf30eab3254" alt="Match Selection Page" width="200"/> |
| Click on the area where the starting location of the robot was, and use the counter as needed. | <img src="https://github.com/user-attachments/assets/839813c9-7762-4644-b500-4f9a0cf5c53c" alt="Starting Location" width="200"/> |
| This is your Teleop page. | <img src="https://github.com/user-attachments/assets/3025be9d-9373-47c7-ac3e-adf9bf41aaa5" alt="Teleop Page" width="200"/> |
| This is your Endgame page. Finish it with a nice Slide to Finalize. | <img src="https://github.com/user-attachments/assets/511edcd7-3af4-4b86-9189-9566686566c1" alt="Endgame Page" width="200"/> |
| It gives you a compacted QR code with all the details for the scout. If you are using the Opintel Scouz plugin (BLE PAN), the other swipe initiates the data transactions, and you will come to the home page. If you want to see the past matches, you can always click on the 3 bars/navigation rail thingy and go to logs. It shows something like this: | <img src="https://github.com/user-attachments/assets/fd1e38da-0e32-42e7-8938-7a29c9a712a0" alt="Logs" width="200"/> |

