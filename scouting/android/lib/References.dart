import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class InfiniteZoomImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Sheet'),
      ),
      body:
        Center(
        child: PhotoView(
          imageProvider: AssetImage('assets/ref/Cheat-Sheet.jpg'),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4.0,
        ),
      ),
    );
  }
}