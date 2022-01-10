import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_tensor/app_button.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'face_painter.dart';
import 'camera.service.dart';
import 'facenet.service.dart';
import 'ml_kit_service.dart';

class SignIn extends StatefulWidget {
  final CameraDescription cameraDescription;

  const SignIn({
    Key? key,
    required this.cameraDescription,
  }) : super(key: key);

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final CameraService _cameraService = CameraService();
  final MLKitService _mlKitService = MLKitService();
  final FaceNetService _faceNetService = FaceNetService();

  Future? _initializeControllerFuture;

  bool cameraInitializated = false;
  bool _detectingFaces = false;
  bool pictureTaked = false;

  bool _saving = false;

  String imagePath = "";
  Size? imageSize;
  Face? faceDetected;

  @override
  void initState() {
    super.initState();

    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  _start() async {
    _initializeControllerFuture =
        _cameraService.startService(widget.cameraDescription);
    await _initializeControllerFuture;

    setState(() {
      cameraInitializated = true;
    });

    _frameFaces();
  }

  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlKitService.getFacesFromImage(image);

          if (faces != null) {
            if (faces.length > 0) {
              setState(() {
                faceDetected = faces[0];
              });

              if (_saving) {
                _saving = false;
                _faceNetService.setCurrentPrediction(image, faceDetected!);
              }
            } else {
              setState(() {
                faceDetected = null;
              });
            }
          }

          _detectingFaces = false;
        } catch (e) {
          _detectingFaces = false;
        }
      }
    });
  }

  Future<bool> onShot() async {
    if (faceDetected == null) {
      showDialog(
        context: context,
        builder: (context) {
          return const AlertDialog(
            content: Text('No face detected!'),
          );
        },
      );

      return false;
    } else {
      _saving = true;

      await Future.delayed(const Duration(milliseconds: 500));
      await _cameraService.cameraController.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));
      XFile file = await _cameraService.takePicture();

      setState(() {
        pictureTaked = true;
        imagePath = file.path;
      });

      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          title: Text(
            faceDetected != null ? "Face Detected" : "Face is not Detected",
            style: TextStyle(
                color: faceDetected != null ? Colors.green : Colors.red),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (pictureTaked) {
                      return SizedBox(
                        width: width,
                        height: height,
                        child: Transform(
                            alignment: Alignment.center,
                            child: const FittedBox(
                              fit: BoxFit.cover,
                            ),
                            transform: Matrix4.rotationY(mirror)),
                      );
                    } else {
                      return Transform.scale(
                        scale: 1.0,
                        child: AspectRatio(
                          aspectRatio: MediaQuery.of(context).size.aspectRatio,
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.fitHeight,
                              child: SizedBox(
                                width: width,
                                height: width *
                                    _cameraService
                                        .cameraController.value.aspectRatio,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: <Widget>[
                                    CameraPreview(
                                        _cameraService.cameraController),
                                    if (faceDetected != null)
                                      CustomPaint(
                                        painter: FacePainter(
                                            face: faceDetected!,
                                            imageSize: imageSize!),
                                      )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          height: 60,
          width: 80,
          child: AppButton(
            onPressed: onShot,
            icon: const Icon(
              Icons.camera,
              color: Colors.white,
            ),
          ),
        ));
  }
}
