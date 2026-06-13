import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../services/post_service.dart';
import '../../utils/image_picker_utils.dart';
import 'map_picker_screen.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/app_colors.dart';
import '../../../utils/custom_snackbar.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({Key? key}) : super(key: key);

  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final PostService _postService = PostService();
  
  String _type = 'lost';
  String _category = 'Elektronik';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  XFile? _imageFile;
  
  bool _isLoading = false;

  final List<String> _categories = ['Elektronik', 'Dokumen', 'Pakaian', 'Aksesoris', 'Kendaraan', 'Lainnya'];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePickerUtils.pickImageWithDialog(context);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => MapPickerScreen(initialPosition: _selectedLocation))
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLocation = result['position'] as LatLng?;
        _selectedAddress = result['address'] as String?;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      CustomSnackBar.show(context, 'Harap pilih lokasi kejadian', isError: true);
      return;
    }
    
    if (_imageFile == null) {
      CustomSnackBar.show(context, 'Harap unggah foto barang', isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Upload Image
      String imageUrl = await _postService.uploadImage(_imageFile!);
      
      // 2. Create Post
      Map<String, dynamic> postData = {
        'type': _type,
        'category': _category,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': _selectedDate.toIso8601String(),
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'images': [imageUrl]
      };
      
      await _postService.createPost(postData);
      
      // 3. Refresh Provider and Close
      if (mounted) {
        Provider.of<PostProvider>(context, listen: false).fetchPosts();
        CustomSnackBar.show(context, 'Laporan berhasil dibuat!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      CustomSnackBar.show(context, e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Type Selection (Toggle)
                Text('Jenis Laporan', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'lost'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _type == 'lost' ? AppColors.danger.withOpacity(0.1) : AppColors.surfaceCard,
                            border: Border.all(color: _type == 'lost' ? AppColors.danger : AppColors.borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Kehilangan', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _type == 'lost' ? AppColors.danger : AppColors.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'found'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _type == 'found' ? AppColors.success.withOpacity(0.1) : AppColors.surfaceCard,
                            border: Border.all(color: _type == 'found' ? AppColors.success : AppColors.borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Ditemukan', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _type == 'found' ? AppColors.success : AppColors.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 2. Image Picker
                Text('Foto Barang', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb 
                                ? Image.network(_imageFile!.path, fit: BoxFit.cover, width: double.infinity)
                                : Image.file(File(_imageFile!.path), fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.primary),
                              const SizedBox(height: 12),
                              Text('Ketuk untuk unggah foto utama', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 3. Title
                AppTextField(
                  label: 'Judul Laporan',
                  hint: 'Contoh: Dompet Hitam Kulit',
                  controller: _titleController,
                  validator: (val) => val!.isEmpty ? 'Judul tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),
                
                // 4. Category
                Text('Kategori', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: Theme.of(context).textTheme.bodyLarge))).toList(),
                  onChanged: (val) => setState(() => _category = val!),
                ),
                const SizedBox(height: 20),
                
                // 5. Description
                AppTextField(
                  label: 'Deskripsi Detail',
                  hint: 'Sebutkan ciri-ciri khusus barang tersebut...',
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (val) => val!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
                const SizedBox(height: 24),
                
                // 6. Date
                Text('Tanggal Kejadian', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(DateFormat('dd MMMM yyyy').format(_selectedDate), style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 7. Location
                Text('Lokasi Kejadian', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedLocation == null ? AppColors.danger : AppColors.primary, width: _selectedLocation == null ? 1 : 1.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: _selectedLocation == null ? AppColors.danger : AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedLocation == null 
                                ? 'Pilih lokasi di peta' 
                                : (_selectedAddress ?? 'Lokasi telah dipilih (Ketuk untuk ubah)'), 
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _selectedLocation == null ? AppColors.danger : AppColors.textPrimary,
                              fontSize: _selectedLocation != null ? 14 : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                AppButton(
                  text: 'Kirim Laporan',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
