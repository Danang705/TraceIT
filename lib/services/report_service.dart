import 'dart:convert';
import '../models/report.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService = ApiService();

  Future<void> reportPost(String postId, String reason, String description) async {
    final response = await _apiService.post('/reports', {
      'postId': postId,
      'reason': reason,
      'description': description.isNotEmpty ? description : null,
    }, requireAuth: true);

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengirim laporan');
    }
  }

  Future<List<Report>> getReports() async {
    final response = await _apiService.get('/reports', requireAuth: true);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> reportsJson = data['data'];
      return reportsJson.map((json) => Report.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil daftar laporan');
    }
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final response = await _apiService.patch('/reports/$reportId/status', {
      'status': status,
    }, requireAuth: true);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal memperbarui status laporan');
    }
  }
}
