import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../utils/app_colors.dart';
import 'admin_filtered_posts_screen.dart';
import '../../../utils/custom_snackbar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  Map<String, dynamic>? _stats;
  List<User>? _users;
  List<Post>? _posts;
  
  bool _isLoadingStats = true;
  bool _isLoadingUsers = true;
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStats();
    _fetchUsers();
    _fetchPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _adminService.getStatistics();
      setState(() => _stats = stats);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _adminService.getUsers();
      setState(() => _users = users);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await _adminService.getPosts();
      setState(() => _posts = posts);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _toggleBan(User user) async {
    try {
      await _adminService.toggleBanUser(user.id, !user.isBanned);
      CustomSnackBar.show(context, 'Status pengguna diperbarui', isError: false);
      _fetchUsers();
    } catch (e) {
      CustomSnackBar.show(context, e.toString(), isError: true);
    }
  }

  Future<void> _deletePost(Post post) async {
    try {
      await _adminService.deletePost(post.id);
      CustomSnackBar.show(context, 'Laporan dihapus', isError: false);
      _fetchPosts();
      _fetchStats();
    } catch (e) {
      CustomSnackBar.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Dasbor Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Statistik'),
            Tab(icon: Icon(Icons.people), text: 'Pengguna'),
            Tab(icon: Icon(Icons.article), text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildPostsTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_stats == null) return const Center(child: Text('Gagal memuat statistik.'));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatCard(
              'Total Pengguna', 
              _stats!['totalUsers'].toString(), 
              Icons.people_outline, 
              AppColors.primary,
              onTap: () => _tabController.animateTo(1),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Total Laporan', 
              _stats!['totalPosts'].toString(), 
              Icons.article_outlined, 
              AppColors.warning,
              onTap: () => _tabController.animateTo(2),
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Total Klaim', 
              _stats!['totalClaims'].toString(), 
              Icons.handshake_outlined, 
              AppColors.success,
              onTap: () {
                if (_posts == null) return;
                // As an approximation for 'Laporan yang di Klaim' without a specific endpoint,
                // we show posts that are not 'active' (likely claimed or resolved).
                final claimedPosts = _posts!.where((p) => p.status != 'active').toList();
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFilteredPostsScreen(
                  title: 'Laporan yang Diklaim', 
                  posts: claimedPosts,
                  onDelete: _deletePost,
                )));
              }
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              'Laporan Selesai', 
              _stats!['totalResolved'].toString(), 
              Icons.check_circle_outline, 
              AppColors.success,
              onTap: () {
                if (_posts == null) return;
                final resolvedPosts = _posts!.where((p) => p.status == 'resolved' || p.status == 'closed').toList();
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFilteredPostsScreen(
                  title: 'Laporan Selesai', 
                  posts: resolvedPosts,
                  onDelete: _deletePost,
                )));
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
          trailing: Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoadingUsers) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_users == null || _users!.isEmpty) return const Center(child: Text('Tidak ada pengguna.'));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users!.length,
        itemBuilder: (context, index) {
          final user = _users![index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
              ),
              title: Row(
                children: [
                  Flexible(child: Text(user.name, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis)),
                  if (user.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 16, color: AppColors.success),
                  ]
                ],
              ),
              subtitle: Text('${user.email}\nRole: ${user.role.toUpperCase()}', style: Theme.of(context).textTheme.bodySmall),
              isThreeLine: true,
              trailing: user.role == 'admin' 
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('ADMIN', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  : Switch(
                      value: user.isBanned,
                      activeColor: AppColors.danger,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                      onChanged: (val) => _toggleBan(user),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_posts == null || _posts!.isEmpty) return const Center(child: Text('Tidak ada laporan.'));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _fetchPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts!.length,
        itemBuilder: (context, index) {
          final post = _posts![index];
          final isLost = post.type == 'lost';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLost ? AppColors.danger.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLost ? Icons.search_off : Icons.check_circle_outline, 
                  color: isLost ? AppColors.danger : AppColors.success,
                ),
              ),
              title: Text(post.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${post.category} • oleh ${post.user?.name ?? 'Anonim'}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Text(post.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Hapus Laporan'),
                      content: const Text('Tindakan ini tidak dapat dibatalkan. Anda yakin ingin menghapus laporan ini?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                            _deletePost(post);
                          },
                          child: const Text('Hapus'),
                        ),
                      ],
                    )
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
