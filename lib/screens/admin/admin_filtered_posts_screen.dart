import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../utils/app_colors.dart';

class AdminFilteredPostsScreen extends StatelessWidget {
  final String title;
  final List<Post> posts;
  final Function(Post) onDelete;

  const AdminFilteredPostsScreen({
    Key? key, 
    required this.title, 
    required this.posts,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: posts.isEmpty 
        ? const Center(child: Text('Tidak ada laporan di kategori ini.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
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
                                onDelete(post);
                                // Because this is a stateless widget, popping will just return. 
                                // In a real app we'd pop this screen too or use stateful to refresh.
                                // For simplicity, we just trigger the callback which deletes from server.
                                Navigator.pop(context); // Optional: close the filtered screen to refresh Dashboard
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
