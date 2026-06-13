import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/location_service.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService();
  final LocationService _locationService = LocationService();

  List<Post> _posts = [];
  bool _isLoading = false;
  String _error = '';

  String _currentType = 'all'; // 'all', 'lost', 'found'
  double _currentRadius = 0.0; // Default 0.0 (Semua)
  String _searchQuery = '';
  String _currentCategory = '';
  Position? _currentPosition;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get currentType => _currentType;
  double get currentRadius => _currentRadius;
  String get searchQuery => _searchQuery;
  String get currentCategory => _currentCategory;
  Position? get currentPosition => _currentPosition;

  Future<void> fetchPosts() async {
    _isLoading = true; _error = ''; notifyListeners();
    try {
      if (_currentPosition == null) { await _determinePosition(); }
      final fetchedPosts = await _postService.getPosts(
        type: _currentType,
        radius: _currentRadius > 0 ? _currentRadius : null,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _currentCategory.isNotEmpty ? _currentCategory : null,
      );
      _posts = fetchedPosts.where((post) => post.status != 'closed').toList();
    } catch (e) { _error = e.toString().replaceAll('Exception: ', ''); }
    finally { _isLoading = false; notifyListeners(); }
  }

  void setFilterType(String type) { _currentType = type; fetchPosts(); }
  void setRadius(double radius) { _currentRadius = radius; fetchPosts(); }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchPosts();
  }

  void setCategory(String category) {
    _currentCategory = category;
    fetchPosts();
  }

  void clearFilters() {
    _currentType = 'all';
    _searchQuery = '';
    _currentCategory = '';
    fetchPosts();
  }

  Future<void> _determinePosition() async {
    try { _currentPosition = await _locationService.getCurrentPosition(); }
    catch (e) { _error = e.toString().replaceAll('Exception: ', ''); notifyListeners(); }
  }
}
