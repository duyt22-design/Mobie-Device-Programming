import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/drawing_capture.dart';
import '../config/app_localizations.dart';
import '../config/app_settings.dart';
import 'drawing_view_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _dbService.fetchUserHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTaskIcon(String taskTitle) {
    if (taskTitle.contains('Tròn')) return '⭕';
    if (taskTitle.contains('Vuông')) return '⬛';
    if (taskTitle.contains('Sao')) return '⭐';
    if (taskTitle.contains('Tim')) return '❤️';
    if (taskTitle.contains('Nhà')) return '🏠';
    if (taskTitle.contains('Vồng')) return '🌈';
    return '🎨';
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _viewDrawing(Map<String, dynamic> history) {
    final drawingData = history['drawingData'] as String?;
    if (drawingData == null || drawingData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.get('no_drawing'))),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrawingViewScreen(
          taskTitle: history['taskTitle'] ?? '',
          drawingData: drawingData,
          score: (history['score'] as num?)?.toDouble() ?? 0.0,
          timeUsed: history['timeUsed'] ?? 0,
          completedAt: history['completedAt'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, color: Colors.white),
            const SizedBox(width: 8),
            Text(AppLocalizations.get('history').toUpperCase()),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.get('no_history'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.get('new_tasks'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final history = _history[index];
                      final score = (history['score'] as num?)?.toDouble() ?? 0.0;
                      final timeUsed = history['timeUsed'] ?? 0;
                      final drawingData = history['drawingData'] as String?;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getScoreColor(score).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _viewDrawing(history),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Thumbnail hình vẽ hoặc icon
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getScoreColor(score).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: drawingData != null && drawingData.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: () {
                                            try {
                                              final imageBytes = DrawingCapture.decodeDrawing(drawingData);
                                              if (imageBytes != null) {
                                                return Image.memory(
                                                  imageBytes,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    debugPrint('Error loading image: $error');
                                                    return Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 32,
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            } catch (e) {
                                              debugPrint('Error decoding drawing: $e');
                                            }
                                            return Center(
                                              child: Text(
                                                _getTaskIcon(history['taskTitle'] ?? ''),
                                                style: const TextStyle(fontSize: 32),
                                              ),
                                            );
                                          }(),
                                        )
                                      : Center(
                                          child: Text(
                                            _getTaskIcon(history['taskTitle'] ?? ''),
                                            style: const TextStyle(fontSize: 32),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        history['taskTitle'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${AppLocalizations.get('time')}: ${timeUsed ~/ 60}:${(timeUsed % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        history['completedAt'] ?? '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getScoreColor(score),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    score.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// Màn hình xem hình vẽ full size

