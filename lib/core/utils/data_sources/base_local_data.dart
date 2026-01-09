import 'package:hive_ce/hive.dart';
import 'package:waterbus_sdk/utils/path_helper.dart';

import 'package:bb_meet/core/constants/storage_keys.dart';
import 'package:bb_meet/core/services/secure_storage_service.dart';

class BaseLocalData {
  static Future<void> initialBox() async {
    final String? path = await PathHelper.localStoreDirWaterbus;
    Hive.init(path);

    await openBoxApp();
  }

  static Future<void> openBoxApp() async {
    final encryptionKey = await SecureStorageService().getHiveKey();
    final cipher = HiveAesCipher(encryptionKey);

    await _openBox(StorageKeys.boxAuth, cipher);
    await _openBox(StorageKeys.boxRoom, cipher);
    await _openBox(StorageKeys.boxMediaConfig, cipher);
    await _openBox(StorageKeys.boxAppSettings, cipher);
  }

  static Future<void> _openBox(String boxName, HiveCipher cipher) async {
    try {
      // Try to open with encryption
      await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (e) {
      // If failed, it might be unencrypted. Try to open without encryption
      try {
        await Hive.openBox(boxName);
        // If successful, we need to migrate
        final box = Hive.box(boxName);
        final Map<dynamic, dynamic> data = box.toMap();
        await box.close();

        // Delete unencrypted box
        await Hive.deleteBoxFromDisk(boxName);

        // Open with encryption and restore data
        final encryptedBox =
            await Hive.openBox(boxName, encryptionCipher: cipher);
        await encryptedBox.putAll(data);
      } catch (e) {
        // If both failed, just delete and start fresh (worst case)
        await Hive.deleteBoxFromDisk(boxName);
        await Hive.openBox(boxName, encryptionCipher: cipher);
      }
    }
  }
}
