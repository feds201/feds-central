# FRC Robotics Scouting App

The following directory is the source code for the Scouting App created by the [FEDS 201](https://www.feds201.com/) FRC robotics team
out of Rochester High School.

## Description

A feature-packed FRC Scouting App for all your Scouting needs. 

## Getting Started

1. Clone our project using your preferred IDE
2. Ensure the latest [Node.js](https://nodejs.org/en) LTS version is installed by running `node -v` in any terminal
3. Run `choco install -y nodejs` to install Node.
4. Run `npm install` in the project directory via terminal to install dependencies

### Dependencies

- Windows or Linux Device to run Android version of the app
- Mac with Xcode installed (To run the IOS version of the app)
- Android Studio if you are using an Emulator to run Android
- Check package.json for project dependencies

### Installing

- The Bundled app will be on the Google Play Store and Apple App Store

## Executing The App

This Project utilizes [Expo](https://docs.expo.dev/), a React Native framework, to deploy the app.
- **Do not use Expo Go to run this app**
- **Development builds cannot be scanned with QR using the Expo Go app**

### Android Run Instructions

Android Studio is required to create development builds in react native. 
- Install [Android Studio](https://developer.android.com/studio)
- Run `choco install -y microsoft-openjdk11` in the terminal (This app utilizes Expo SDK 49, which uses JDK 11)
- You will also need to install [Android SDK](https://docs.expo.dev/guides/local-app-development/)
- Ensure your Windows [Environment Variables](https://developer.android.com/tools/variables#envar) has a [path called ANDROID_HOME](https://developer.android.com/tools/variables) directed to the SDK folder 
- To set up an Emulator visit [Expo's Guide](https://docs.expo.dev/workflow/android-studio-emulator/).
- To use a local Android device, ensure the device is plugged in with [USB debugging](https://developer.android.com/studio/debug/dev-options) enabled.

- **Build Project with Expo CLI**
1. Run `npx expo install expo-dev-client` (Converts react native code to native android code) [learn more](https://docs.expo.dev/develop/development-builds/introduction/#what-is-expo-dev-client)
2. Create a [development build](https://docs.expo.dev/develop/development-builds/create-a-build/).
3. Run `npx expo start` in terminal
4. Switch to Development Build, and run Android

- **Build Project Locally (Native Files)**
1. Run `npx expo run:android` (This will start installing gradle and native android dependencies)
2. Switch to Development Build, and run Android

### IOS Run Instructions

## Help Us!

If you like what you see and want to help us out, that would be awesome!

We will manually check every pull request, but most likely your change will be reflected in the app.

## Authors

#### Main contributors

Zayn B. ([@BaizaOP](https://github.com/BaizaOP))  
Sukhesh S. ([@Sukhesh07](https://github.com/Sukhesh07))

#### Our Awesome Programming Mentor

Mr. S

## Version History

* Still in development

## License

Add license

## Acknowledgments

ADIT IS AWESOMMEEEEEE!!!!!

Thanks to all of the support from the [FEDS 201](https://www.feds201.com) Robotics team. Go FEDS!
