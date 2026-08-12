import 'dart:convert';
import 'package:http/http.dart' as http;

class KycApiService {
  /// Upload a base64-encoded image to Cloudinary and return the secure URL.
  static Future<String> uploadToCloudinary(String base64) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/dp4sdp25o/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['file'] = 'data:image/png;base64,$base64'
      ..fields['upload_preset'] = 'kyc_uploads';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'];
    }

    throw Exception('Cloudinary upload failed: ${response.statusCode} - $responseBody');
  }
}
