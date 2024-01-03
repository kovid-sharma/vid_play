import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  MyApp(this.cameras);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoScreen(cameras),
    );
  }
}

class VideoScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  VideoScreen(this.cameras);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late List<File> videos = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recordVideo() async {
    if (!_controller.value.isRecordingVideo) {
      try {
        await _initializeControllerFuture;

        final path = DateTime.now().toString() + '.mp4';
        await _controller.startVideoRecording();
      } catch (e) {
        print(e);
      }
    } else {
      try {
        XFile video = await _controller.stopVideoRecording();
        setState(() {
          videos.add(File(video.path));
        });
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        videos.addAll(result.paths.map((path) => File(path!)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                return VideoPlayerWidget(videoPath: videos[index].path);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _recordVideo,
                child: Icon(
                  _controller.value.isRecordingVideo
                      ? Icons.stop
                      : Icons.fiber_manual_record,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _pickVideo,
                child: Icon(Icons.file_upload),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatelessWidget {
  final String videoPath;
  final VideoPlayerController controller;

  VideoPlayerWidget({required this.videoPath})
      : controller = VideoPlayerController.file(File(videoPath));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children:[ AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
              SizedBox(height: 1,)
        ]
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
