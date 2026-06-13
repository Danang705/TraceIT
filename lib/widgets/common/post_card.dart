import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post.dart';
import '../../utils/app_colors.dart';
import 'status_chip.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final double? distanceInKm;

  const PostCard({
    Key? key,
    required this.post,
    required this.onTap,
    this.distanceInKm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format date string to DateTime if possible
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(post.date);
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Stack(
              children: [
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusChip(status: post.type), // 'lost' or 'found'
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User & Time
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            backgroundImage: post.user?.avatarUrl != null
                                ? CachedNetworkImageProvider(post.user!.avatarUrl!)
                                : null,
                            child: post.user?.avatarUrl == null
                                ? const Icon(Icons.person, size: 14, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            parsedDate != null 
                                ? timeago.format(parsedDate, locale: 'id') 
                                : post.date,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      // Distance
                      if (distanceInKm != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${distanceInKm!.toStringAsFixed(1)} km',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
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
