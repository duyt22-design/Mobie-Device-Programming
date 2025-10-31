import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../config/app_localizations.dart';
import '../config/app_settings.dart';

class LeaderboardWidget extends StatefulWidget {
  final int limit;

  const LeaderboardWidget({
    super.key,
    this.limit = 10,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    
    // Auto-refresh mỗi 5 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _loadLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    // Chỉ show loading lần đầu
    if (_leaderboard.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    final data = await DatabaseService().fetchLeaderboard(limit: widget.limit);

    if (mounted) {
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    }
  }

  Widget _buildAvatarWithCrown(String? avatarBase64, int rank) {
    Widget avatar;

    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(avatarBase64);
        avatar = CircleAvatar(
          radius: 30,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        avatar = _buildDefaultAvatar();
      }
    } else {
      avatar = _buildDefaultAvatar();
    }

    // TOP 1: Vương miện vàng đội trên đầu
    if (rank == 1) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          Positioned(
            top: -15,
            child: Icon(
              Icons.workspace_premium,
              color: Colors.amber[700],
              size: 32,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return avatar;
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey.shade300,
      child: const Icon(
        Icons.person,
        size: 35,
        color: Colors.white,
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    IconData? icon;
    Color textColor = Colors.white;

    switch (rank) {
      case 1:
        badgeColor = Colors.amber[600]!; // Vàng
        icon = Icons.military_tech; // Huy chương vàng
        break;
      case 2:
        badgeColor = Colors.grey[400]!; // Bạc
        icon = Icons.military_tech; // Huy chương bạc
        break;
      case 3:
        badgeColor = Colors.brown[400]!; // Đồng
        icon = Icons.military_tech; // Huy chương đồng
        break;
      case 4:
      case 5:
        badgeColor = Colors.blue[300]!; // Badge đặc biệt
        icon = Icons.star; // Ngôi sao
        break;
      default:
        badgeColor = Colors.grey[300]!;
        textColor = Colors.black87;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        boxShadow: rank <= 5
            ? [
                BoxShadow(
                  color: badgeColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: textColor, size: 20)
            : Text(
                '#$rank',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Text(AppLocalizations.get('no_leaderboard_data')),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final user = _leaderboard[index];
          final rank = index + 1;
          final isTopFive = rank <= 5;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isTopFive
                  ? LinearGradient(
                      colors: [
                        _getTopFiveGradientStart(rank),
                        _getTopFiveGradientEnd(rank),
                      ],
                    )
                  : null,
              color: isTopFive ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isTopFive
                      ? _getTopFiveGradientStart(rank).withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isTopFive ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRankBadge(rank),
                  const SizedBox(width: 12),
                  _buildAvatarWithCrown(user['avatar'], rank),
                ],
              ),
              title: Text(
                user['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isTopFive ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                '${AppLocalizations.get('completed')}: ${user['totalTasksCompleted'] ?? 0} ${AppLocalizations.get('tasks')}',
                style: TextStyle(
                  fontSize: 12,
                  color: isTopFive ? Colors.white70 : Colors.grey[600],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: isTopFive ? Colors.white : Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(user['averageScore'] ?? 0).toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isTopFive ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getTopFiveGradientStart(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[400]!; // Vàng
      case 2:
        return Colors.grey[400]!; // Bạc
      case 3:
        return Colors.brown[300]!; // Đồng
      case 4:
      case 5:
        return Colors.blue[400]!; // Xanh
      default:
        return Colors.white;
    }
  }

  Color _getTopFiveGradientEnd(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!;
      case 2:
        return Colors.grey[500]!;
      case 3:
        return Colors.brown[400]!;
      case 4:
      case 5:
        return Colors.blue[600]!;
      default:
        return Colors.white;
    }
  }
}

