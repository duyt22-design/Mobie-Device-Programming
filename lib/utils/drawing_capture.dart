import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/drawing_point.dart';

class DrawingCapture {
  /// Chuyển list of DrawingPoints thành base64 string
  static Future<String?> captureDrawing({
    required List<DrawingPoint?> points,
    int width = 800,
    int height = 800,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Vẽ nền trắng
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );
      
      // Vẽ các nét từ points
      for (int i = 0; i < points.length - 1; i++) {
        if (points[i] != null && points[i + 1] != null) {
          canvas.drawLine(
            points[i]!.offset,
            points[i + 1]!.offset,
            points[i]!.paint,
          );
        }
      }
      
      // Convert thành image
      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;
      
      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('Error capturing drawing: $e');
      return null;
    }
  }
  
  /// Decode base64 string thành Uint8List để hiển thị
  static Uint8List? decodeDrawing(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('Error decoding drawing: $e');
      return null;
    }
  }
}

