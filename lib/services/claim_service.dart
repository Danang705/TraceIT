import 'dart:convert';
import '../models/claim.dart';
import 'api_service.dart';

class ClaimService {
  final ApiService _apiService = ApiService();

  Future<void> submitClaim(String postId, String message, String? proofImage) async {
    Map<String, dynamic> body = {'message': message};
    if (proofImage != null) {
      body['proofImage'] = proofImage;
    }

    final response = await _apiService.post('/posts/$postId/responses', body);
    
    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengirim klaim');
    }
  }

  Future<List<Claim>> getPostClaims(String postId) async {
    final response = await _apiService.get('/posts/$postId/responses');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> claimsJson = data['data'];
      return claimsJson.map((json) => Claim.fromJson(json)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal mengambil data klaim');
    }
  }

  Future<void> updateClaimStatus(String claimId, String status) async {
    final response = await _apiService.patch(
      '/responses/$claimId/status', 
      {'status': status}
    );
    
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Gagal merespons klaim');
    }
  }
}
