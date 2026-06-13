import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_colors.dart';
import '../../utils/geocoding_util.dart';
import '../../../utils/custom_snackbar.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const MapPickerScreen({Key? key, this.initialPosition}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedPosition;
  String? _selectedAddress;
  bool _isLoadingLocation = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    if (_selectedPosition == null) {
      _getCurrentLocation();
    } else {
      _fetchAddressForPosition(_selectedPosition!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddressForPosition(LatLng position) async {
    setState(() => _isSearching = true);
    final address = await GeocodingUtil.getAddressFromLatLng(position);
    if (mounted) {
      setState(() {
        _selectedAddress = address;
        _isSearching = false;
      });
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    final position = await GeocodingUtil.getLatLngFromAddress(query);
    if (mounted) {
      if (position != null) {
        setState(() {
          _selectedPosition = position;
        });
        _mapController.move(position, 15.0);
        await _fetchAddressForPosition(position);
      } else {
        setState(() => _isSearching = false);
        CustomSnackBar.show(context, 'Lokasi tidak ditemukan', isError: false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() { _isLoadingLocation = true; });
    try {
      Position position = await Geolocator.getCurrentPosition();
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = newPos;
        _mapController.move(newPos, 15.0);
      });
      await _fetchAddressForPosition(newPos);
    } catch (e) {
      // Default to Jakarta if location fails
      setState(() {
        _selectedPosition = const LatLng(-6.200000, 106.816666);
      });
      await _fetchAddressForPosition(_selectedPosition!);
    } finally {
      if (mounted) setState(() { _isLoadingLocation = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition ?? const LatLng(-6.200000, 106.816666),
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedPosition = point;
                  _selectedAddress = null; // reset while fetching
                });
                _fetchAddressForPosition(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.antigrafity.traceit',
              ),
              if (_selectedPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60.0,
                      height: 60.0,
                      point: _selectedPosition!,
                      child: const Icon(Icons.location_on, color: AppColors.danger, size: 50.0),
                    ),
                  ],
                ),
            ],
          ),
          
          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari alamat atau lokasi...',
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
          ),

          if (_isLoadingLocation || _isSearching)
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(width: 16),
                      Text(_isSearching ? "Mencari detail lokasi..." : "Mengambil lokasi Anda..."),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            right: 16,
            bottom: 180, // Move up to make room for address card
            child: FloatingActionButton(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.my_location, color: Colors.white),
              onPressed: _getCurrentLocation,
            ),
          ),

          if (_selectedPosition != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress ?? 'Memuat alamat...',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _selectedAddress != null ? () {
                          // Return both position and address
                          Navigator.pop(context, {
                            'position': _selectedPosition,
                            'address': _selectedAddress,
                          });
                        } : null,
                        child: const Text('Pilih Lokasi Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

