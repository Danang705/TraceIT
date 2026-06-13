import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

import '../../models/chat.dart';
import '../../models/claim.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/constants.dart';
import '../../utils/image_picker_utils.dart';
import '../../utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/custom_snackbar.dart';
import '../post/map_picker_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final Chat chat;
  final Claim? forwardClaim;

  const ChatRoomScreen({Key? key, required this.chat, this.forwardClaim}) : super(key: key);

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late IO.Socket _socket;
  final ChatService _chatService = ChatService();
  final PostService _postService = PostService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Provider.of<AuthProvider>(context, listen: false).user!.id;
    _fetchMessages();
    _connectSocket();
  }

  Future<void> _saveLastReadId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_read_${widget.chat.id}', id);
  }

  void _connectSocket() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    
    _socket = IO.io(Constants.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setAuth({'token': token})
      .build());

    _socket.connect();

    _socket.onConnect((_) {
      _socket.emit('join_room', widget.chat.id);
    });

    _socket.on('receive_message', (data) {
      if (mounted) {
        final newMsg = Message.fromJson(data);
        setState(() {
          // Remove optimistic message if matches
          _messages.removeWhere((m) => m.senderId == newMsg.senderId && m.content == newMsg.content && m.type == newMsg.type && m.id.length < 20); // Optimistic ID is timestamp, short length
          _messages.insert(0, newMsg);
        });
        _scrollToBottom();
        _saveLastReadId(newMsg.id);
      }
    });

    _socket.on('receive_location', (data) {
      if (mounted) {
        final newMsg = Message.fromJson(data);
        setState(() {
          _messages.removeWhere((m) => m.senderId == newMsg.senderId && m.content == newMsg.content && m.type == newMsg.type && m.id.length < 20);
          _messages.insert(0, newMsg);
        });
        _scrollToBottom();
        _saveLastReadId(newMsg.id);
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final msgs = await _chatService.getMessages(widget.chat.id);
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      if (msgs.isNotEmpty) {
        _saveLastReadId(msgs.first.id);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackBar.show(context, e.toString(), isError: true);
    }
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _socket.emit('send_message', {
      'roomId': widget.chat.id,
      'chat_id': widget.chat.id,
      'senderId': _currentUserId,
      'content': text,
      'type': 'text',
    });

    // Optimistic Update
    final tempMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // short id to identify optimistic message
      chatId: widget.chat.id,
      senderId: _currentUserId,
      content: text,
      type: 'text',
      createdAt: DateTime.now().toIso8601String(),
    );
    setState(() {
      _messages.insert(0, tempMsg);
    });
    _scrollToBottom();

    _msgController.clear();
  }

  Future<void> _sendImage() async {
    final pickedFile = await ImagePickerUtils.pickImageWithDialog(context);
    
    if (pickedFile != null) {
      CustomSnackBar.show(context, 'Mengunggah gambar...');
      try {
        final imageUrl = await _postService.uploadImage(pickedFile);
        
        _socket.emit('send_message', {
          'roomId': widget.chat.id,
          'chat_id': widget.chat.id,
          'senderId': _currentUserId,
          'content': imageUrl,
          'type': 'image',
        });
        
        // Optimistic Update
        final tempMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: widget.chat.id,
          senderId: _currentUserId,
          content: imageUrl,
          type: 'image',
          createdAt: DateTime.now().toIso8601String(),
        );
        setState(() {
          _messages.insert(0, tempMsg);
        });
        _scrollToBottom();
      } catch (e) {
        CustomSnackBar.show(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _shareLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result['position'] != null) {
      final LatLng position = result['position'];
      final String address = result['address'] ?? '';

      // Send via socket
      _socket.emit('send_location', {
        'roomId': widget.chat.id,
        'chat_id': widget.chat.id,
        'senderId': _currentUserId,
        'lat': position.latitude,
        'lng': position.longitude,
      });

      // Optimistic update for location message
      final content = jsonEncode({
        'lat': position.latitude,
        'lng': position.longitude,
        'address': address,
      });

      final tempMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chat.id,
        senderId: _currentUserId,
        content: content,
        type: 'location',
        createdAt: DateTime.now().toIso8601String(),
      );

      setState(() {
        _messages.insert(0, tempMsg);
      });
      _scrollToBottom();
    }
  }

  void _openGoogleMaps(String content) async {
    try {
      final data = jsonDecode(content);
      final lat = data['lat'];
      final lng = data['lng'];
      if (lat != null && lng != null) {
        final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        try {
          final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
          if (!launched && mounted) {
            CustomSnackBar.show(context, 'Tidak dapat membuka Google Maps', isError: true);
          }
        } catch (e) {
          if (mounted) {
            CustomSnackBar.show(context, 'Tidak dapat membuka Google Maps', isError: true);
          }
        }
      }
    } catch (e) {
      CustomSnackBar.show(context, 'Format lokasi tidak valid', isError: true);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceCard,
              backgroundImage: widget.chat.partner?.avatarUrl != null 
                  ? CachedNetworkImageProvider(widget.chat.partner!.avatarUrl!) : null,
              child: widget.chat.partner?.avatarUrl == null ? const Icon(Icons.person, size: 20, color: AppColors.textSecondary) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chat.partner?.name ?? 'Pengguna', style: Theme.of(context).textTheme.titleMedium),
                  Text(widget.chat.post?.title ?? 'Laporan', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderColor, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      return _buildChatBubble(msg, isMe);
                    },
                  ),
          ),
          if (widget.forwardClaim != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.05),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Kirim bukti klaim Anda ke obrolan ini agar pemilik dapat melihatnya secara langsung.', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (widget.forwardClaim!.message.isNotEmpty) {
                        _socket.emit('send_message', {
                          'roomId': widget.chat.id,
                          'chat_id': widget.chat.id,
                          'senderId': _currentUserId,
                          'content': widget.forwardClaim!.message,
                          'type': 'text',
                        });
                      }
                      if (widget.forwardClaim!.proofImage != null) {
                        _socket.emit('send_message', {
                          'roomId': widget.chat.id,
                          'chat_id': widget.chat.id,
                          'senderId': _currentUserId,
                          'content': widget.forwardClaim!.proofImage,
                          'type': 'image',
                        });
                      }
                      CustomSnackBar.show(context, 'Bukti klaim berhasil dikirim!', isError: false);
                    },
                    child: const Text('Kirim Bukti'),
                  )
                ],
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Message msg, bool isMe) {
    DateTime? parsedDate;
    try { parsedDate = DateTime.parse(msg.createdAt); } catch (_) {}
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
              border: isMe ? null : Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.type == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: msg.content,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => const SizedBox(height: 150, child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  )
                else if (msg.type == 'location')
                  InkWell(
                    onTap: () => _openGoogleMaps(msg.content),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, color: isMe ? Colors.white : AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lokasi Dibagikan',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ketuk untuk membuka Google Maps',
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.open_in_new, color: isMe ? Colors.white70 : AppColors.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    msg.content,
                    style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (parsedDate != null)
            Text(
              timeago.format(parsedDate, locale: 'id'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 28),
              onPressed: _sendImage,
            ),
            IconButton(
              icon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 28),
              onPressed: _shareLocation,
            ),
            Expanded(
              child: TextField(
                controller: _msgController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
