import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _photoUrlKey = 'user_photo_url';
  static const _photoDataKey = 'user_photo_data'; // Base64 encoded image

  // Read the JWT from storage
  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Write the JWT to storage
  Future<void> writeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Delete the JWT from storage
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Read the cached photo URL from storage
  Future<String?> readPhotoUrl() async {
    return await _storage.read(key: _photoUrlKey);
  }

  // Write the photo URL to storage
  Future<void> writePhotoUrl(String photoUrl) async {
    await _storage.write(key: _photoUrlKey, value: photoUrl);
  }

  // Delete the photo URL from storage
  Future<void> deletePhotoUrl() async {
    await _storage.delete(key: _photoUrlKey);
  }

  // Read the cached photo data (base64) from storage
  Future<String?> readPhotoData() async {
    return await _storage.read(key: _photoDataKey);
  }

  // Write the photo data (base64) to storage
  Future<void> writePhotoData(String photoData) async {
    await _storage.write(key: _photoDataKey, value: photoData);
  }

  // Delete the photo data from storage
  Future<void> deletePhotoData() async {
    await _storage.delete(key: _photoDataKey);
  }
}
