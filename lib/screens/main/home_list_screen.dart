import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/post.dart';
import '../../widgets/common/skeleton_card.dart';
import '../../widgets/common/status_chip.dart';
import '../post/post_detail_screen.dart';
import '../post/my_posts_screen.dart';
import '../../utils/app_colors.dart';

class HomeListScreen extends StatefulWidget {
  const HomeListScreen({Key? key}) : super(key: key);

  @override
  _HomeListScreenState createState() => _HomeListScreenState();
}

class _HomeListScreenState extends State<HomeListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchPosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Consumer<PostProvider>(
      builder: (context, provider, child) {
        final myPosts = provider.posts.where((p) => p.user?.id == user?.id).toList();
        final lostCount = myPosts.where((p) => p.type == 'lost').length;
        final foundCount = myPosts.where((p) => p.type == 'found').length;
        final closedCount = myPosts.where((p) => p.status == 'closed' || p.status == 'resolved').length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F8),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchPosts(),
            edgeOffset: MediaQuery.of(context).padding.top + 60,
            child: CustomScrollView(
              slivers: [
                // Pinned Avatar Header
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _AvatarHeaderDelegate(
                    user: user,
                    statusBarHeight: MediaQuery.of(context).padding.top,
                  ),
                ),
                // Laporanmu card (scrolls up under the pinned header)
                SliverToBoxAdapter(
                  child: _buildLaporanmuCard(foundCount, lostCount, closedCount),
                ),
                // Sticky Search Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickySearchDelegate(
                    searchController: _searchController,
                    provider: provider,
                  ),
                ),
                // Posts Feed
                _buildPostsList(provider),
                // Bottom padding for navbar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLaporanmuCard(int foundCount, int lostCount, int closedCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Laporanmu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.9)),
                      ],
                    ),
                  ),
                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        _buildStatItem('$foundCount', 'Barang Ditemukan'),
                        _buildStatDivider(),
                        _buildStatItem('$lostCount', 'Barang Hilang'),
                        _buildStatDivider(),
                        _buildStatItem('$closedCount', 'Laporan Selesai'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildPostsList(PostProvider provider) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonCard(),
          ),
          childCount: 3,
        ),
      );
    }

    if (provider.error.isNotEmpty && provider.posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(provider.error, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchPosts(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 80, color: AppColors.borderColor),
              const SizedBox(height: 16),
              Text(
                'Tidak ada laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Ubah filter radius atau jenis laporan',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = provider.posts[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPostCard(post),
          );
        },
        childCount: provider.posts.length,
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(post.date);
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
                    ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(status: post.type),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        parsedDate != null
                            ? timeago.format(parsedDate, locale: 'id')
                            : post.date,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Avatar Header Delegate
class _AvatarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final dynamic user;
  final double statusBarHeight;

  _AvatarHeaderDelegate({required this.user, required this.statusBarHeight});

  @override
  double get minExtent => statusBarHeight + 84;

  @override
  double get maxExtent => statusBarHeight + 84;

  @override
  bool shouldRebuild(covariant _AvatarHeaderDelegate oldDelegate) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final userName = user?.name ?? 'Pengguna';

    return Container(
      padding: EdgeInsets.only(top: statusBarHeight + 16, bottom: 0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withOpacity(0.3),
              backgroundImage: user?.avatarUrl != null
                  ? CachedNetworkImageProvider(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? const Icon(Icons.person, size: 32, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hallo, $userName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Temukan barangmu yang hilang',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky Search Bar Delegate
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final PostProvider provider;

  _StickySearchDelegate({
    required this.searchController,
    required this.provider,
  });

  @override
  double get minExtent => 68;

  @override
  double get maxExtent => 68;

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF5F5F8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: overlapsContent
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: 'Cari Laporan',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (value) {
                  provider.setSearchQuery(value.trim());
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: overlapsContent
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: provider.currentRadius,
                icon: const SizedBox.shrink(),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 0.0, child: Text('Semua')),
                  DropdownMenuItem(value: 5.0, child: Text('5 km')),
                  DropdownMenuItem(value: 10.0, child: Text('10 km')),
                  DropdownMenuItem(value: 20.0, child: Text('20 km')),
                  DropdownMenuItem(value: 50.0, child: Text('50 km')),
                ],
                onChanged: (val) {
                  if (val != null) provider.setRadius(val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
