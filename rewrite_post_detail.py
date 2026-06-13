import re

with open('lib/screens/post/post_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
imports_to_add = """import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
"""
content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + imports_to_add)

# Find where to inject new methods (e.g., right before _fetchPostAddress)
methods_to_add = """
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
                    final String text = "TraceIT - ${widget.post.title}\\nKategori: ${widget.post.category}\\n\\nBantu temukan/klaim barang ini sekarang!";
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

  void _reportPost() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Postingan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Beritahu kami mengapa postingan ini bermasalah:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Alasan pelaporan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              CustomSnackBar.show(context, 'Laporan telah dikirim ke Admin untuk ditinjau.', isError: false);
            },
            child: const Text('Kirim', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
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
"""

content = content.replace("Future<void> _fetchPostAddress() async {", methods_to_add + "\n  Future<void> _fetchPostAddress() async {")

# Replace build method entirely
new_build = """  @override
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
                        Text('Komentar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Segera Hadir', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 16, backgroundColor: Colors.grey[300], child: const Icon(Icons.person, size: 16, color: Colors.white)),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Tulis komentar publik... (fitur sedang dikembangkan)', style: TextStyle(color: AppColors.textSecondary))),
                        ],
                      ),
                    ),
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
"""

# Extract everything before `Widget build(BuildContext context) {`
build_start = content.find("  @override\n  Widget build(BuildContext context) {")
if build_start != -1:
    # Also find _buildBottomAction and keep it, or we just replace the build method.
    # Actually, we can use regex to replace the build method.
    pass

import re
# Match build method up to `  Widget _buildBottomAction(bool isLost) {`
pattern = re.compile(r"  @override\n  Widget build\(BuildContext context\) \{.*?(?=  Widget _buildBottomAction\(bool isLost\) \{)", re.DOTALL)
content = pattern.sub(new_build + "\n", content)

with open('lib/screens/post/post_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
