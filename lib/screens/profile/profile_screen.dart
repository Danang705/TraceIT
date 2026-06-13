import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/notification_service.dart';

import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../services/auth_service.dart';
import '../auth/auth_choice_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../post/my_posts_screen.dart';
import '../../utils/image_picker_utils.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../../utils/custom_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      // Aktifkan: re-register token ke server
      await NotificationService().initialize();
    } else {
      // Nonaktifkan: hapus token dari server agar push berhenti
      await NotificationService().unregisterToken();
    }

    if (mounted) setState(() => _notificationsEnabled = value);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => AuthChoiceScreen()),
                (route) => false
              );
            }, 
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        if (user == null) return const Center(child: CircularProgressIndicator());

        // Get post counts
        final postProvider = Provider.of<PostProvider>(context);
        final myPosts = postProvider.posts.where((p) => p.user?.id == user.id).toList();
        final lostCount = myPosts.where((p) => p.type == 'lost').length;
        final foundCount = myPosts.where((p) => p.type == 'found').length;
        final closedCount = myPosts.where((p) => p.status == 'closed' || p.status == 'resolved').length;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 16),
                
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Profil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // User Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          backgroundImage: user.avatarUrl != null 
                              ? CachedNetworkImageProvider(user.avatarUrl!) 
                              : null,
                          child: user.avatarUrl == null 
                              ? const Icon(Icons.person, size: 32, color: AppColors.primary) 
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Edit Profil Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: user),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit Profil',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Ringkasan Aktivitas
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Ringkasan Aktivitas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _buildProfileStat('$lostCount', 'Barang Hilang'),
                      const SizedBox(width: 12),
                      _buildProfileStat('$foundCount', 'Barang Ditemukan'),
                      const SizedBox(width: 12),
                      _buildProfileStat('$closedCount', 'Barang Kembali'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Lihat Selengkapnya
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lihat Selengkapnya',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Akun & Aplikasi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Akun & Aplikasi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Pengaturan Notifikasi dengan Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 24),
                      title: const Text(
                        'Pengaturan Notifikasi',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _notificationsEnabled ? 'Notifikasi aktif' : 'Notifikasi dinonaktifkan',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotification,
                        activeTrackColor: AppColors.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ),
                ),

                if (user.role == 'admin') ...[
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Dasbor Admin',
                    subtitle: 'Kelola laporan & pengguna',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboardScreen()));
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 120), // Navbar padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.textSecondary, size: 24),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }

}

class EditProfileScreen extends StatefulWidget {
  final dynamic user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  XFile? _newAvatarFile;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePickerUtils.pickImageWithDialog(context);
    if (pickedFile != null) {
      setState(() {
        _newAvatarFile = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      String? newAvatarUrl;
      if (_newAvatarFile != null) {
        newAvatarUrl = await _authService.uploadAvatar(_newAvatarFile!);
      } else {
        newAvatarUrl = widget.user.avatarUrl;
      }

      final updatedUser = await _authService.updateProfile(
        avatar: newAvatarUrl, 
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).updateUser(updatedUser);
        CustomSnackBar.show(context, 'Profil berhasil diperbarui', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: AppColors.surfaceCard,
                      backgroundImage: _newAvatarFile != null 
                          ? (kIsWeb ? NetworkImage(_newAvatarFile!.path) : FileImage(File(_newAvatarFile!.path))) as ImageProvider
                          : (widget.user.avatarUrl != null ? CachedNetworkImageProvider(widget.user.avatarUrl!) : null),
                      child: _newAvatarFile == null && widget.user.avatarUrl == null 
                          ? const Icon(Icons.person, size: 64, color: AppColors.textSecondary) 
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              AppTextField(
                label: 'Nama Lengkap',
                controller: TextEditingController(text: widget.user.name),
                enabled: false,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                label: 'Email',
                controller: TextEditingController(text: widget.user.email),
                enabled: false,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                label: 'Nomor Telepon',
                controller: _phoneController,
                enabled: true,
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                label: 'Alamat',
                controller: _addressController,
                maxLines: 3,
                enabled: true,
                prefixIcon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              
              AppButton(
                text: 'Simpan Perubahan',
                isLoading: _isLoading,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
