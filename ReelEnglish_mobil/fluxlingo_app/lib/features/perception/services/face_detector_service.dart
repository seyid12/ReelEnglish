import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isInitialized = false;

  final _distractionController = StreamController<bool>.broadcast();
  Stream<bool> get distractionStream => _distractionController.stream;

  FaceDetectorService() {
    final options = FaceDetectorOptions(
      enableClassification: true, // Gözlerin açık/kapalı olma ihtimali için gerekli
      enableTracking: true,
      minFaceSize: 0.15,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Ön kamerayı bul
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Performans için düşük çözünürlük
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      
      // Kameradan canlı akış almaya başla
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _processImage(image, frontCamera.sensorOrientation);
        }
      });
    } catch (e) {
      debugPrint('Kamera başlatılamadı: $e');
    }
  }

  Future<void> _processImage(CameraImage image, int sensorOrientation) async {
    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, sensorOrientation);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      bool isDistracted = false;

      for (Face face in faces) {
        final rotY = face.headEulerAngleY; // Kafanın y eksenindeki dönüşü (sağa sola bakma)
        final leftEyeOpen = face.leftEyeOpenProbability;
        final rightEyeOpen = face.rightEyeOpenProbability;

        // Kafa 20 dereceden fazla sağa veya sola dönükse
        bool isHeadTurned = rotY != null && (rotY > 20 || rotY < -20);
        bool areEyesClosed = false;

        if (leftEyeOpen != null && rightEyeOpen != null) {
          // Gözlerin ikisi de %20 ihtimalden daha az açıksa (kapalı sayılır)
          if (leftEyeOpen < 0.2 && rightEyeOpen < 0.2) {
            areEyesClosed = true;
          }
        }

        if (isHeadTurned || areEyesClosed) {
          isDistracted = true;
          break; // İlk eşleşmede sinyali tetikle
        }
      }

      // Mevcut durumu stream üzerinden yayınla
      _distractionController.add(isDistracted);
    } catch (e) {
      debugPrint('Yüz işleme hatası: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final bytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }
    final allBytes = bytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

    return InputImage.fromBytes(
      bytes: allBytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void dispose() {
    _distractionController.close();
    _cameraController?.dispose();
    _faceDetector.close();
    _isInitialized = false;
  }
}
