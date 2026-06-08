import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static const String cloudName = 'alejandrannjuarez';
  static const String uploadPreset = 'tripplanner_destinations';

  Future<String> uploadImage(XFile image) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await image.readAsBytes();

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No se pudo subir la imagen.');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary no devolvió una URL válida.');
    }

    return secureUrl;
  }
}