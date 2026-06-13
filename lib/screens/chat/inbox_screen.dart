import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import 'chat_room_screen.dart';
import '../../utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/custom_snackbar.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ChatService _chatService = ChatService();
  List<Chat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).user!.id;
      final chats = await _chatService.getChats(currentUserId);
      final prefs = await SharedPreferences.getInstance();
      final deletedChats = prefs.getStringList('deleted_chats') ?? [];
      
      final activeChats = chats.where((c) => !deletedChats.contains(c.id)).toList();
      
      for (var chat in activeChats) {
        try {
          final messages = await _chatService.getMessages(chat.id, page: 1);
          if (messages.isNotEmpty) {
            chat.lastMessage = messages.first;
            
            final lastReadId = prefs.getString('last_read_${chat.id}');
            int unread = 0;
            if (lastReadId != null) {
              final index = messages.indexWhere((m) => m.id == lastReadId);
              if (index != -1) {
                unread = messages.take(index).where((m) => m.senderId != currentUserId).length;
              } else {
                unread = messages.where((m) => m.senderId != currentUserId).length;
              }
            } else {
              unread = messages.where((m) => m.senderId != currentUserId).length;
            }
            chat.unreadCount = unread;
          } else {
            chat.unreadCount = 0;
          }
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          _chats = activeChats;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteChatLocally(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedChats = prefs.getStringList('deleted_chats') ?? [];
    if (!deletedChats.contains(chatId)) {
      deletedChats.add(chatId);
      await prefs.setStringList('deleted_chats', deletedChats);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pesan'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.borderColor),
                      const SizedBox(height: 16),
                      Text('Belum ada pesan', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Pesan masuk akan muncul di sini', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchChats,
                  child: ListView.separated(
                    itemCount: _chats.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderColor),
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final partnerName = chat.partner?.name ?? 'Pengguna';
                      final lastMsg = chat.lastMessage?.content ?? 'Belum ada pesan';
                      final isLost = chat.post?.type == 'lost';
                      
                      DateTime? parsedDate;
                      if (chat.lastMessage?.createdAt != null) {
                        try {
                          parsedDate = DateTime.parse(chat.lastMessage!.createdAt);
                        } catch (_) {}
                      }

                      return Dismissible(
                        key: Key(chat.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.danger,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Hapus Obrolan', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: const Text('Apakah Anda yakin ingin menghapus obrolan ini? Semua riwayat pesan lokal akan disembunyikan.'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Hapus', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        onDismissed: (direction) {
                          _deleteChatLocally(chat.id);
                          setState(() {
                            _chats.removeAt(index);
                          });
                          CustomSnackBar.show(context, 'Pesan dihapus', isError: false);
                        },
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChatRoomScreen(chat: chat))
                            ).then((_) => _fetchChats());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  backgroundImage: chat.partner?.avatarUrl != null 
                                      ? CachedNetworkImageProvider(chat.partner!.avatarUrl!) : null,
                                  child: chat.partner?.avatarUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              partnerName, 
                                              style: Theme.of(context).textTheme.titleMedium,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (parsedDate != null)
                                            Text(
                                              timeago.format(parsedDate, locale: 'id'),
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: chat.unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                                                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lastMsg, 
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: chat.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                                fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                              ),
                                              maxLines: 1, 
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (chat.unreadCount > 0)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                chat.unreadCount.toString(),
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isLost ? AppColors.tagLostBg : AppColors.tagFoundBg,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          chat.post?.title ?? 'Laporan',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isLost ? AppColors.tagLostText : AppColors.tagFoundText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
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
