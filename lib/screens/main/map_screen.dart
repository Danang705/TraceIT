import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/post_provider.dart';
import '../post/post_detail_screen.dart';
import '../../utils/app_colors.dart';
import '../../../utils/custom_snackbar.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSatellite = false;
  String _filterMode = 'all'; // 'all', 'lost', 'found'

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

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    CustomSnackBar.show(context, 'Mencari...', isError: false);

    try {
      // 1. Search locally for items first
      final provider = Provider.of<PostProvider>(context, listen: false);
      final queryLower = query.toLowerCase();
      final matchingPosts = provider.posts.where((p) => 
        p.title.toLowerCase().contains(queryLower) || 
        p.description.toLowerCase().contains(queryLower)
      ).toList();

      if (matchingPosts.isNotEmpty) {
        // Center on the first matching item
        final post = matchingPosts.first;
        final newCenter = LatLng(post.latitude, post.longitude);
        _mapController.move(newCenter, 16.0);
        
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        return;
      }

      // 2. If no items match, search globally via Nominatim (Location Search)
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'com.antigrafity.traceit'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newCenter = LatLng(lat, lon);
          _mapController.move(newCenter, 14.0);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        } else {
          CustomSnackBar.show(context, 'Lokasi atau barang tidak ditemukan', isError: false);
        }
      }
    } catch (e) {
      CustomSnackBar.show(context, 'Gagal melakukan pencarian', isError: true);
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(1.0, 18.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(1.0, 18.0));
  }

  Widget _buildFilterButton(String label, String value, IconData icon, Color color) {
    final isSelected = _filterMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300),
            boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndMoveToMyLocation(PostProvider provider) async {
    CustomSnackBar.show(context, 'Mengambil lokasi saat ini...', isError: false);
    await provider.fetchPosts(); // This refreshes posts and location internally
    
    if (provider.currentPosition != null) {
      _mapController.move(
        LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude), 
        15.0
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } else {
      CustomSnackBar.show(context, 'Gagal mendapatkan lokasi', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.currentPosition == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final initialPos = provider.currentPosition != null
            ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
            : const LatLng(-6.200000, 106.816666);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialPos,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatellite 
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.antigrafity.traceit',
                ),
                MarkerLayer(
                  markers: _buildMarkers(provider),
                ),
              ],
            ),
            // Search Bar & Filters
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari Lokasi atau BarangR...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: AppColors.primary),
                            onPressed: _searchLocation,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _searchLocation(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFilterButton('Semua', 'all', Icons.layers, AppColors.primary),
                      const SizedBox(width: 8),
                      _buildFilterButton('Hilang', 'lost', Icons.search_off, AppColors.danger),
                      const SizedBox(width: 8),
                      _buildFilterButton('Ditemukan', 'found', Icons.check_circle_outline, AppColors.success),
                    ],
                  )
                ],
              ),
            ),
            // Floating Buttons
            Positioned(
              right: 16,
              bottom: 100, // Increased to avoid overlapping with BottomNavigationBar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'layer',
                    mini: true,
                    backgroundColor: Colors.white,
                    child: Icon(_isSatellite ? Icons.map : Icons.satellite, color: AppColors.primary),
                    onPressed: () => setState(() => _isSatellite = !_isSatellite),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'zoomIn',
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: AppColors.primary),
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'zoomOut',
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: AppColors.primary),
                    onPressed: _zoomOut,
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'location',
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () => _fetchAndMoveToMyLocation(provider),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Marker> _buildMarkers(PostProvider provider) {
    List<Marker> markers = [];

    // Add User Current Location Marker
    if (provider.currentPosition != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Text('Anda', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.location_history, color: AppColors.primary, size: 40.0),
            ],
          ),
        ),
      );
    }

    // Add Posts Markers
    for (var post in provider.posts) {
      if (_filterMode == 'lost' && post.type != 'lost') continue;
      if (_filterMode == 'found' && post.type != 'found') continue;
      
      final isLost = post.type == 'lost';
      markers.add(
        Marker(
          width: 60.0,
          height: 60.0,
          point: LatLng(post.latitude, post.longitude),
          child: GestureDetector(
            onTap: () {
              _showPostPreview(context, post);
            },
            child: Icon(
              Icons.location_on,
              color: isLost ? Colors.red : Colors.green,
              size: 45.0,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showPostPreview(BuildContext context, post) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title, 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              SizedBox(height: 8),
              Text(post.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))
                    );
                  },
                  child: Text('Lihat Detail'),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
