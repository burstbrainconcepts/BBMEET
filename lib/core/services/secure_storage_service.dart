import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyHive = 'hive_encryption_key';

  Future<List<int>> getHiveKey() async {
    final keyStr = await _storage.read(key: _keyHive);
    if (keyStr == null) {
      final key = Hive.generateSecureKey();
      await _storage.write(key: _keyHive, value: base64UrlEncode(key));
      return key;
    }
    return base64Url.decode(keyStr);
  }
}
