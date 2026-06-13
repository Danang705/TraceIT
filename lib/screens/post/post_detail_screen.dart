import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/post.dart';
import '../../models/claim.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/claim_service.dart';
import '../../services/post_service.dart';
import '../../services/chat_service.dart';
import '../../models/comment.dart';
import '../../services/comment_service.dart';
import '../../services/report_service.dart';
import '../chat/chat_room_screen.dart';
import '../../utils/image_picker_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../utils/constants.dart';
import '../../providers/post_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/geocoding_util.dart';
import '../../../utils/custom_snackbar.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ClaimService _claimService = ClaimService();
  final PostService _postService = PostService();
  final ChatService _chatService = ChatService();
  final CommentService _commentService = CommentService();
  final ReportService _reportService = ReportService();
  
  List<Claim> _claims = [];
  bool _isLoadingClaims = false;
  
  bool _isOwner = false;
  String _currentPostStatus = '';
  bool _hasClaimed = false;
  Claim? _myClaim;
  String? _postAddress;

  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  final TextEditingController _commentInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _isOwner = widget.post.user?.id == auth.user?.id;
    _currentPostStatus = widget.post.status;
    
    // Check locally first in case backend blocks non-owners from getting claims
    _checkLocalClaim();
    
    // Always fetch claims to check if current user has already claimed from server
    _fetchClaims();

    _fetchPostAddress();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentInputController.dispose();
    super.dispose();
  }

  
  Future<void> _sharePost() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bagikan Laporan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(
                  icon: Icons.share,
                  label: 'Bagikan',
                  onTap: () {
                    Navigator.pop(context);
                    final String text = "TraceIT - ${widget.post.title}\nKategori: ${widget.post.category}\n\nBantu temukan/klaim barang ini sekarang!";
                    Share.share(text);
                  },
                ),
                _buildShareOption(
                  icon: Icons.copy,
                  label: 'Salin Tautan',
                  onTap: () {
                    Navigator.pop(context);
                    final String link = "https://traceit.app/post/${widget.post.id}";
                    Clipboard.setData(ClipboardData(text: link)).then((_) {
                      CustomSnackBar.show(context, 'Tautan berhasil disalin!', isError: false);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.post.latitude},${widget.post.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) CustomSnackBar.show(context, 'Tidak dapat membuka Maps', isError: true);
    }
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: Hero(
              tag: 'post_image_${widget.post.id}',
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }));
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _commentService.getComments(widget.post.id);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentInputController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      CustomSnackBar.show(context, 'Silakan login terlebih dahulu untuk berkomentar.', isError: true);
      return;
    }

    try {
      _commentInputController.clear();
      FocusScope.of(context).unfocus();
      await _commentService.addComment(widget.post.id, text);
      _fetchComments(); // Reload comments
      if (mounted) {
        CustomSnackBar.show(context, 'Komentar berhasil ditambahkan', isError: false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Komentar'),
        content: const Text('Anda yakin ingin menghapus komentar ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      )
    );

    if (confirm != true) return;

    try {
      await _commentService.deleteComment(commentId);
      _fetchComments();
      if (mounted) {
        CustomSnackBar.show(context, 'Komentar berhasil dihapus', isError: false);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _reportPost() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      CustomSnackBar.show(context, 'Silakan login terlebih dahulu untuk melaporkan postingan.', isError: true);
      return;
    }

    String selectedReason = 'Spam';
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Laporkan Postingan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih alasan mengapa postingan ini bermasalah:'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ['Spam', 'Penipuan', 'Konten tidak pantas', 'Lainnya'].map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedReason = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Deskripsi Tambahan (Opsional):'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan detail tambahan laporan Anda...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final desc = descriptionController.text.trim();
                  Navigator.pop(context);
                  CustomSnackBar.show(context, 'Mengirim laporan...');
                  try {
                    await _reportService.reportPost(widget.post.id, selectedReason, desc);
                    if (context.mounted) {
                      CustomSnackBar.show(context, 'Laporan berhasil terkirim. Terima kasih atas masukan Anda.', isError: false);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
                    }
                  }
                },
                child: const Text('Kirim Laporan'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildClaimCard(Claim claim) {
    Color statusColor;
    if (claim.status == 'pending') statusColor = AppColors.warning;
    else if (claim.status == 'accepted') statusColor = AppColors.success;
    else statusColor = AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 14, backgroundColor: Colors.white, child: const Icon(Icons.person, size: 14, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          claim.user?.name ?? 'Seseorang', 
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (claim.user?.isVerified == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: AppColors.success),
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(claim.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                )
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claim.message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
                if (claim.proofImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(imageUrl: claim.proofImage!, height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                ],
                
                // Actions
                if (claim.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Tolak',
                          isOutlined: true,
                          color: AppColors.danger,
                          onPressed: () => _handleClaimStatus(claim, 'rejected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Terima',
                          color: AppColors.success,
                          onPressed: () => _handleClaimStatus(claim, 'accepted'),
                        ),
                      ),
                    ],
                  )
                ] else if (claim.status == 'accepted') ...[
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Chat dengan ${claim.user?.name ?? "Pengguna"}',
                    color: AppColors.primary,
                    onPressed: () => _navigateToChat(claim),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _fetchPostAddress() async {
    final address = await GeocodingUtil.getAddressFromLatLng(LatLng(widget.post.latitude, widget.post.longitude));
    if (mounted) {
      setState(() {
        _postAddress = address;
      });
    }
  }

  Future<void> _navigateToChat(Claim claim, {bool forward = false}) async {
    CustomSnackBar.show(context, 'Membuka chat...');
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chats = await _chatService.getChats(auth.user!.id);
      
      // Strictly find by responseId first to distinguish multiple claims from the same user
      Chat? targetChat;
      try {
        targetChat = chats.firstWhere((c) => c.responseId == claim.id);
      } catch (_) {
        // Fallback if responseId is somehow not returned by backend
        targetChat = chats.firstWhere(
          (c) => c.postId == widget.post.id && c.partner?.id == claim.user?.id,
          orElse: () => throw Exception('Ruang obrolan belum dibuat oleh sistem.'),
        );
      }
      
      if (mounted && targetChat != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(chat: targetChat!, forwardClaim: forward ? claim : null),
          ),
        );
      }
    } catch (e) {
      CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }



  Future<void> _fetchClaims() async {
    setState(() => _isLoadingClaims = true);
    try {
      final claims = await _claimService.getPostClaims(widget.post.id);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _claims = claims;
        if (!_hasClaimed) {
          _hasClaimed = claims.any((c) => c.user?.id == auth.user?.id);
        }
        try {
          _myClaim = claims.firstWhere((c) => c.user?.id == auth.user?.id);
        } catch (_) {}
      });
    } catch (e) {
      if (_isOwner) {
        CustomSnackBar.show(context, 'Gagal memuat daftar klaim: $e', isError: true);
      }
    } finally {
      setState(() => _isLoadingClaims = false);
    }
  }

  Future<void> _checkLocalClaim() async {
    final prefs = await SharedPreferences.getInstance();
    final claimed = prefs.getStringList('claimed_posts') ?? [];
    if (claimed.contains(widget.post.id) && mounted) {
      setState(() {
        _hasClaimed = true;
      });
    }
  }

  Future<void> _saveLocalClaim() async {
    final prefs = await SharedPreferences.getInstance();
    final claimed = prefs.getStringList('claimed_posts') ?? [];
    if (!claimed.contains(widget.post.id)) {
      claimed.add(widget.post.id);
      await prefs.setStringList('claimed_posts', claimed);
    }
  }

  void _showClaimDialog() {
    final _messageController = TextEditingController();
    XFile? _proofImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Punya Informasi?', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Bantu pemilik dengan memberikan informasi yang jelas.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Pesan / Bukti',
                      hint: 'Tuliskan informasi Anda di sini...',
                      controller: _messageController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text('Foto Bukti (Opsional)', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await ImagePickerUtils.pickImageWithDialog(context);
                        if (pickedFile != null) {
                          setModalState(() => _proofImage = pickedFile);
                        }
                      },
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid),
                        ),
                        child: _proofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: kIsWeb 
                                    ? Image.network(_proofImage!.path, fit: BoxFit.cover, width: double.infinity)
                                    : Image.file(File(_proofImage!.path), fit: BoxFit.cover, width: double.infinity),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 32),
                                  const SizedBox(height: 8),
                                  Text('Ketuk untuk unggah foto', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary))
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Kirim Informasi',
                      onPressed: () async {
                        if (_messageController.text.trim().isEmpty) {
                          CustomSnackBar.show(context, 'Pesan tidak boleh kosong', isError: true);
                          return;
                        }
                        
                        Navigator.pop(context); // close modal immediately
                        CustomSnackBar.show(context, 'Mengirim...');
                        
                        try {
                          String? imageUrl;
                          if (_proofImage != null) {
                            imageUrl = await _postService.uploadImage(_proofImage!);
                          }
                          
                          await _claimService.submitClaim(widget.post.id, _messageController.text, imageUrl);
                          await _saveLocalClaim();
                          
                          if (mounted) {
                            setState(() {
                              _hasClaimed = true;
                            });
                            CustomSnackBar.show(context, 'Berhasil mengirim tanggapan!', isError: false);
                          }
                        } catch (e) {
                          if (mounted) {
                            CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _handleClaimStatus(Claim claim, String status) async {
    try {
      await _claimService.updateClaimStatus(claim.id, status);
      
      if (status == 'accepted') {
        // Chat room is created by backend, but we no longer send the claim here.
        // It will be sent by the claimer when they enter the chat.
      }
      
      _fetchClaims(); // Refresh list
      CustomSnackBar.show(context, 'Status berhasil diubah', isError: false);
    } catch (e) {
      CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _closePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Laporan?'),
        content: const Text('Apakah barang ini sudah kembali ke pemilik aslinya? Laporan yang ditandai selesai akan disembunyikan dari daftar utama dan tidak bisa diubah lagi.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Ya, Selesai', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoadingClaims = true);
    try {
      await _postService.updatePostStatus(widget.post.id, 'closed');
      setState(() => _currentPostStatus = 'closed');
      CustomSnackBar.show(context, 'Laporan berhasil diselesaikan!', isError: false);
      if (mounted) {
        Provider.of<PostProvider>(context, listen: false).fetchPosts(); // Refresh home list
      }
    } catch (e) {
      CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isLoadingClaims = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.post.type == 'lost';
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(widget.post.date);
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _sharePost,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'report') _reportPost();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: AppColors.danger, size: 20),
                        SizedBox(width: 8),
                        Text('Laporkan', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.post.imageUrl != null) {
                        _showImageFullScreen(widget.post.imageUrl!);
                      }
                    },
                    child: Hero(
                      tag: 'post_image_${widget.post.id}',
                      child: widget.post.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.post.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                            errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 60, color: Colors.grey)),
                          )
                        : Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0, height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0, left: 0, right: 0, height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.4), Colors.transparent]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: AppColors.primary,
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              transform: Matrix4.translationValues(0, -32, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isLost ? AppColors.danger.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isLost ? Icons.search : Icons.check_circle, size: 16, color: isLost ? AppColors.danger : AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                isLost ? 'Kehilangan' : 'Ditemukan',
                                style: TextStyle(color: isLost ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              parsedDate != null ? timeago.format(parsedDate, locale: 'id') : widget.post.date,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.post.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
                          child: const Icon(Icons.category_outlined, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.post.category,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Deskripsi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        widget.post.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Lokasi', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _openInMaps,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Buka di Maps'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(widget.post.latitude, widget.post.longitude),
                                initialZoom: 15.0,
                                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                              ),
                              children: [
                                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.antigrafity.traceit'),
                                MarkerLayer(
                                  markers: [
                                    Marker(point: LatLng(widget.post.latitude, widget.post.longitude), child: Icon(Icons.location_on, color: isLost ? AppColors.danger : AppColors.success, size: 48))
                                  ],
                                )
                              ],
                            ),
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.place, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _postAddress ?? 'Memuat alamat...',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (widget.post.user != null) ...[
                      Text('Dilaporkan oleh', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.05), AppColors.surfaceCard], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                              child: CircleAvatar(
                                radius: 26, backgroundColor: AppColors.primary.withOpacity(0.1),
                                backgroundImage: widget.post.user!.avatarUrl != null ? CachedNetworkImageProvider(widget.post.user!.avatarUrl!) : null,
                                child: widget.post.user!.avatarUrl == null ? const Icon(Icons.person, color: AppColors.primary, size: 28) : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(child: Text(widget.post.user!.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                      if (widget.post.user!.isVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, size: 16, color: AppColors.success),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(widget.post.user!.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Komentar (${_comments.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingComments && _comments.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primary)))
                    else ...[
                      if (_comments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: const Center(
                            child: Text(
                              'Belum ada komentar. Tulis komentar pertama!',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            final isCommentOwner = auth.user?.id == comment.userId;
                            final showDeleteButton = isCommentOwner || _isOwner;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withOpacity(0.1),
                                    backgroundImage: comment.userAvatarUrl != null ? CachedNetworkImageProvider(comment.userAvatarUrl!) : null,
                                    child: comment.userAvatarUrl == null ? const Icon(Icons.person, size: 18, color: AppColors.primary) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                comment.userName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              timeago.format(comment.createdAt, locale: 'id'),
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          comment.content,
                                          style: const TextStyle(fontSize: 13, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (showDeleteButton)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                                      onPressed: () => _deleteComment(comment.id),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentInputController,
                                decoration: const InputDecoration(
                                  hintText: 'Tulis komentar publik...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                ),
                                style: const TextStyle(fontSize: 13),
                                maxLines: null,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: AppColors.primary, size: 20),
                              onPressed: _submitComment,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (_isOwner) ...[
                      Text('Tanggapan Masuk', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_isLoadingClaims)
                        const Center(child: CircularProgressIndicator())
                      else if (_claims.isEmpty)
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('Belum ada tanggapan', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text('Jika ada yang menemukan atau mengklaim, akan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _claims.length,
                          itemBuilder: (context, index) {
                            return _buildClaimCard(_claims[index]);
                          },
                        ),
                    ]
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 16)],
          ),
          child: _buildBottomAction(isLost),
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isLost) {
    if (_isOwner) {
      if (_currentPostStatus != 'closed') {
        return AppButton(
          text: 'Tandai Laporan Selesai',
          isOutlined: true,
          color: AppColors.success,
          onPressed: _closePost,
        );
      } else {
        return AppButton(
          text: 'Laporan Telah Selesai',
          color: AppColors.success,
          onPressed: () {},
        );
      }
    } else {
      if (_currentPostStatus == 'open' || _currentPostStatus == 'active') {
        if (_hasClaimed) {
          if (_myClaim?.status == 'accepted') {
            return AppButton(
              text: 'Chat dengan Pemilik (Kirim Bukti)',
              color: AppColors.primary,
              onPressed: () => _navigateToChat(_myClaim!, forward: true),
            );
          }
          return const AppButton(
            text: 'Anda sudah mengirim informasi',
            color: AppColors.textSecondary,
            onPressed: null,
          );
        }
        return AppButton(
          text: isLost ? 'Saya Menemukan Barang Ini!' : 'Ini Barang Saya!',
          color: AppColors.primary,
          onPressed: _showClaimDialog,
        );
      } else {
        return const AppButton(
          text: 'Kasus Sudah Ditutup',
          color: AppColors.textSecondary,
          onPressed: null,
        );
      }
    }
  }
}
