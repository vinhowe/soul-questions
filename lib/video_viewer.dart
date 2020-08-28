import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class VideoViewer extends StatefulWidget {
  @override
  _VideoViewerState createState() => _VideoViewerState();

  String videoPath;

  VideoViewer(this.videoPath);
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;

  @override
  void initState() {
    _setupVideoPlayer();
    super.initState();
  }

  Future<void> _setupVideoPlayer() async {
    videoPlayerController = VideoPlayerController.file(File(widget.videoPath));

    try {
      await videoPlayerController.initialize();
    } catch (e) {
      print(e);
      rethrow;
    }

    double aspectRatio = videoPlayerController.value.aspectRatio ?? 1;

    chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        allowFullScreen: false,
        autoPlay: true,
        aspectRatio: aspectRatio,
        errorBuilder: (context, error) {
          return Center(
              child: Text(
            "error $error",
            style: TextStyle(color: Colors.white),
          ));
        });

    if (aspectRatio <= 1) {
      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    } else {
      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }

    setState(() {
      chewieController = chewieController;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData appThemeData = Theme.of(context);
    ThemeData themeData =
        ThemeData.dark().copyWith(accentColor: appThemeData.accentColor);

    Widget centerWidget = CircularProgressIndicator();

    if (chewieController != null) {
      centerWidget = Chewie(
        controller: chewieController,
      );
    }

    return Theme(
      data: themeData,
      child: Container(
        child: Scaffold(
          body: Center(child: centerWidget),
        ),
      ),
    );
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController.dispose();
    super.dispose();
  }
}
