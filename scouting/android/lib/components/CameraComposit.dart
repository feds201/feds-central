import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:platform/platform.dart';

Future<void> _showCameraOptions(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);

  if (image != null) {
    // Handle the image file (e.g., send it to the app)
    print('Image path: ${image.path}');
  }
}

Widget buildCameraBox() {
  return LayoutBuilder(
    builder: (context, constraints) {
      double screenWidth = MediaQuery.of(context).size.width - 25;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (LocalPlatform().isAndroid || LocalPlatform().isIOS) {
                      bool? takePicture = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Take Picture'),
                            content:
                                const Text('Do you want to take a picture?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );

                      if (takePicture == true) {
                        await _showCameraOptions(context);
                      }
                    } else {
                      // Show a message that the camera is not supported on this platform
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Camera Not Supported'),
                            content: const Text(
                                'The camera is not supported on this platform.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    padding: const EdgeInsets.all(6),
                    color: Colors.blue, // Change color as needed
                    dashPattern: const [8, 4],
                    strokeWidth: 2,
                    child: Container(
                      width: double.infinity,
                      height: 200, // Adjust height as needed
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.blue, // Change color as needed
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Camera",
                  style: const TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
