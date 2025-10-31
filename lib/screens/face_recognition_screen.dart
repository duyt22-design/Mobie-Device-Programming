import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/database_service.dart';
import '../main.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
    ),
  );
  
  bool _isDetecting = false;
  bool _faceDetected = false;
  int _detectionCount = 0;
  String _statusMessage = 'Đang khởi tạo camera...';
  List<CameraDescription>? _cameras;
  final List<String> _faceSignatures = []; // Lưu signatures để match

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _statusMessage = 'Không tìm thấy camera');
        return;
      }

      // Tìm camera trước (front camera)
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _statusMessage = 'Hãy nhìn vào camera');
        _startImageStream();
      }
    } catch (e) {
      setState(() => _statusMessage = 'Lỗi khởi tạo camera: $e');
    }
  }

  void _startImageStream() {
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      _detectFaces(image).then((_) {
        _isDetecting = false;
      });
    });
  }

  InputImageRotation _getImageRotation() {
    // Lấy device rotation
    final sensorOrientation = _cameraController?.description.sensorOrientation ?? 0;
    
    // Android front camera cần rotation đặc biệt
    if (_cameraController?.description.lensDirection == CameraLensDirection.front) {
      return InputImageRotation.rotation270deg;
    }
    
    // Map sensor orientation to InputImageRotation
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> _detectFaces(CameraImage image) async {
    try {
      // Tạo InputImage từ CameraImage
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Xác định format dựa trên platform
      final format = image.format.group == ImageFormatGroup.yuv420
          ? InputImageFormat.yuv420
          : InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: _getImageRotation(),
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final List<Face> faces = await _faceDetector.processImage(inputImage);
      
      print('👁️ Recognition - Faces detected: ${faces.length}'); // Debug log

      if (mounted) {
        if (faces.isNotEmpty) {
          // Face detected
          final face = faces.first;
          final signature = _generateFaceSignature(face);
          
          setState(() {
            _faceDetected = true;
            _detectionCount++;
            _statusMessage = 'Đang nhận diện... $_detectionCount/5';
          });

          _faceSignatures.add(signature);

          // Nếu phát hiện khuôn mặt 5 lần liên tiếp → đăng nhập thành công (giảm từ 10)
          if (_detectionCount >= 5) {
            await _performCheckIn();
          }
        } else {
          setState(() {
            _faceDetected = false;
            _detectionCount = 0;
            _faceSignatures.clear();
            _statusMessage = 'Không phát hiện khuôn mặt';
          });
        }
      }
    } catch (e) {
      print('Error detecting faces: $e');
    }
  }

  String _generateFaceSignature(Face face) {
    // Tạo signature đơn giản từ face bounding box và rotation
    final box = face.boundingBox;
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    
    return '${box.width.toInt()}_${box.height.toInt()}_'
           '${headEulerAngleY.toInt()}_${headEulerAngleZ.toInt()}_'
           '${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _performCheckIn() async {
    await _cameraController?.stopImageStream();
    
    setState(() => _statusMessage = 'Đang xác thực với database...');

    // Tạo signature tổng hợp từ nhiều lần scan
    final combinedSignature = _faceSignatures.join('|');

    // Gọi faceLogin API
    final result = await DatabaseService().faceLogin(combinedSignature);

    if (mounted) {
      if (result['success'] == true) {
        final userName = result['user']['name'] ?? 'Người dùng';
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đăng nhập thành công!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chào mừng $userName quay trở lại!',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DrawingApp(),
                    ),
                  );
                },
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        );
      } else {
        final errorMsg = result['error'] ?? 'Không nhận diện được người dùng';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _detectionCount = 0;
          _faceSignatures.clear();
          _statusMessage = 'Hãy thử lại';
        });
        _startImageStream();
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Nhận diện khuôn mặt'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Camera Preview
                Center(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                
                // Face detection overlay
                if (_faceDetected)
                  Center(
                    child: Container(
                      width: 250,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.green,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                
                // Status message at top
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _faceDetected
                          ? Colors.green.withOpacity(0.8)
                          : Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _faceDetected
                              ? Icons.face_retouching_natural
                              : Icons.face_retouching_off,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_faceDetected)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: LinearProgressIndicator(
                              value: _detectionCount / 5,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Instructions at bottom
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• Đặt khuôn mặt trong khung hình\n'
                          '• Giữ khuôn mặt ổn định\n'
                          '• Đảm bảo ánh sáng đủ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

