import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://projekakhirpaa.onrender.com/api/auth/forgot-password');
  final body = jsonEncode({
    'email': 'danangtanggul123@gmail.com',
  });
  final headers = {'Content-Type': 'application/json'};
  
  try {
    final response = await http.post(url, headers: headers, body: body);
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
