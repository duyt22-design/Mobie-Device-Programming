import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with WidgetsBindingObserver {
  final _dbService = DatabaseService();
  Map<String, dynamic>? _adminStats;
  Map<String, dynamic>? _demographicsStats;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatistics();
    
    // Auto-refresh mỗi 5 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadStatistics();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh khi app được mở lại
    if (state == AppLifecycleState.resumed && mounted) {
      _loadStatistics();
    }
  }

  Future<void> _loadStatistics() async {
    // Chỉ show loading lần đầu
    if (_adminStats == null || _demographicsStats == null) {
      setState(() => _isLoading = true);
    } else {
      // Show refresh indicator nhỏ khi auto-refresh
      setState(() => _isRefreshing = true);
    }
    
    try {
      final admin = await _dbService.fetchAdminStatistics();
      final demographics = await _dbService.fetchDemographicsStatistics();
      
      if (mounted) {
        setState(() {
          _adminStats = admin;
          _demographicsStats = demographics;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: Colors.white),
            SizedBox(width: 8),
            Text('BÁO CÁO THỐNG KÊ'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadStatistics,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tổng quan section
                    _buildSectionHeader('📊 Tổng quan', Icons.dashboard),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Tổng người dùng',
                            value: '${_demographicsStats?['totalUsers'] ?? 0}',
                            color: Colors.green,
                            icon: Icons.people,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Hoàn thành',
                            value: '${_adminStats?['totalCompletions'] ?? 0}',
                            color: Colors.blue,
                            icon: Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Theo độ tuổi section
                    _buildSectionHeader('👥 Theo độ tuổi', Icons.people_alt),
                    const SizedBox(height: 12),
                    _buildAgeGroupsList(),
                    const SizedBox(height: 24),

                    // Theo giới tính section
                    _buildSectionHeader('🚻 Theo giới tính', Icons.wc),
                    const SizedBox(height: 12),
                    _buildGenderStats(),
                  ],
                ),
              ),
            ),
        ),
        // Auto-refresh indicator ở góc trên phải
        if (_isRefreshing)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang cập nhật...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupsList() {
    final ageGroups = _demographicsStats?['ageGroups'] ?? {};
    final totalUsers = _demographicsStats?['totalUsers'] ?? 1;

    final groups = [
      {'key': 'under18', 'label': 'Dưới 18 tuổi'},
      {'key': '18-25', 'label': '18-25 tuổi'},
      {'key': '26-35', 'label': '26-35 tuổi'},
      {'key': '36-45', 'label': '36-45 tuổi'},
      {'key': 'over45', 'label': 'Trên 45 tuổi'},
    ];

    return Column(
      children: groups.map((group) {
        final count = ageGroups[group['key']] ?? 0;
        final percentage = totalUsers > 0 ? (count / totalUsers * 100) : 0.0;
        
        return _buildAgeGroupItem(
          label: group['label']!,
          count: count,
          percentage: percentage,
        );
      }).toList(),
    );
  }

  Widget _buildAgeGroupItem({
    required String label,
    required int count,
    required double percentage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                percentage.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$count người dùng',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderStats() {
    final genderStats = _demographicsStats?['genderStats'] ?? {};
    final totalUsers = _demographicsStats?['totalUsers'] ?? 1;
    
    final male = genderStats['male'] ?? 0;
    final female = genderStats['female'] ?? 0;
    final other = genderStats['other'] ?? 0;
    
    final malePercentage = totalUsers > 0 ? (male / totalUsers * 100) : 0.0;
    final femalePercentage = totalUsers > 0 ? (female / totalUsers * 100) : 0.0;
    final otherPercentage = totalUsers > 0 ? (other / totalUsers * 100) : 0.0;

    return Column(
      children: [
        _buildGenderCard(
          label: 'Nam',
          count: male,
          percentage: malePercentage,
          color: Colors.blue.shade600,
          icon: Icons.male,
        ),
        const SizedBox(height: 12),
        _buildGenderCard(
          label: 'Nữ',
          count: female,
          percentage: femalePercentage,
          color: Colors.pink.shade400,
          icon: Icons.female,
        ),
        const SizedBox(height: 12),
        _buildGenderCard(
          label: 'Khác',
          count: other,
          percentage: otherPercentage,
          color: Colors.purple.shade400,
          icon: Icons.wc,
        ),
      ],
    );
  }

  Widget _buildGenderCard({
    required String label,
    required int count,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count người dùng',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

