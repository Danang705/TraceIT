import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/notification_provider.dart';
import '../../models/notification_item.dart';
import '../../utils/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => provider.clear(),
                child: const Text(
                  'Hapus Semua',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final notifications = provider.claimNotifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi klaim barang akan muncul di sini',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // No API – just triggers rebuild
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationTile(
                  item: item,
                  index: index,
                  onDismissed: () {
                    provider.removeById(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notifikasi dihapus'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Batal',
                          onPressed: () => provider.add(item),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final NotificationItem item;
  final int index;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.item,
    required this.index,
    required this.onDismissed,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    // Stagger animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    final title = widget.item.title.toLowerCase();
    final body = widget.item.body.toLowerCase();
    // Detect claim-related notifications
    if (title.contains('klaim') || body.contains('klaim') ||
        title.contains('claim') || body.contains('claim')) {
      return Icons.assignment_outlined;
    }
    if (title.contains('diterima') || body.contains('diterima') ||
        title.contains('accepted') || body.contains('accepted') ||
        title.contains('approved') || body.contains('approved')) {
      return Icons.check_circle_outline;
    }
    if (title.contains('ditolak') || body.contains('ditolak') ||
        title.contains('rejected') || body.contains('rejected')) {
      return Icons.cancel_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _getIconColor() {
    final title = widget.item.title.toLowerCase();
    final body = widget.item.body.toLowerCase();
    if (title.contains('diterima') || body.contains('diterima') ||
        title.contains('accepted') || body.contains('accepted')) {
      return AppColors.success;
    }
    if (title.contains('ditolak') || body.contains('ditolak') ||
        title.contains('rejected') || body.contains('rejected')) {
      return AppColors.danger;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dismissible(
          key: ValueKey(widget.item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDismissed(),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeago.format(widget.item.timestamp, locale: 'id'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
