import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingUtil {
  static Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'com.antigrafity.traceit'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Alamat tidak ditemukan';
      }
    } catch (e) {
      // Ignored
    }
    return 'Gagal mengambil alamat';
  }

  static Future<LatLng?> getLatLngFromAddress(String address) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'com.antigrafity.traceit'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      // Ignored
    }
    return null;
  }
}
