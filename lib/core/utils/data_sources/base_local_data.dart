import 'package:hive_ce/hive.dart';
import 'package:waterbus_sdk/utils/path_helper.dart';

import 'package:bb_meet/core/constants/storage_keys.dart';
import 'package:bb_meet/core/services/secure_storage_service.dart';

class BaseLocalData {
  static bool _isInitialized = false;
  static final Map<String, Future<void>> _openingBoxes = {};

  static Future<void> initialBox() async {
    if (_isInitialized) {
      return;
    }

    final String? path = await PathHelper.localStoreDirWaterbus;
    Hive.init(path);

    await openBoxApp();
    _isInitialized = true;
  }

  static Future<void> openBoxApp() async {
    final encryptionKey = await SecureStorageService().getHiveKey();
    final cipher = HiveAesCipher(encryptionKey);

    // Open boxes sequentially to avoid race conditions
    await _openBox(StorageKeys.boxAuth, cipher);
    await _openBox(StorageKeys.boxRoom, cipher);
    await _openBox(StorageKeys.boxMediaConfig, cipher);
    await _openBox(StorageKeys.boxAppSettings, cipher);
  }

  /// Safely get a box, ensuring it's open first
  static Box getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call BaseLocalData.initialBox() first.');
    }
    return Hive.box(boxName);
  }

  static Future<void> _openBox(String boxName, HiveCipher cipher) async {
    // Check if box is already open
    if (Hive.isBoxOpen(boxName)) {
      return;
    }

    try {
      // Try to open with encryption
      await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (e) {
      // If failed, it might be unencrypted. Try to open without encryption
      try {
        // Check again if box was opened by another process
        if (Hive.isBoxOpen(boxName)) {
          return;
        }

        final box = await Hive.openBox(boxName);
        // If successful, we need to migrate
        final Map<dynamic, dynamic> data = box.toMap();
        
        // Close the box before deleting
        await box.close();
        
        // Wait a bit to ensure the box is fully closed
        await Future.delayed(const Duration(milliseconds: 100));

        // Delete unencrypted box
        await Hive.deleteBoxFromDisk(boxName);

        // Wait a bit before reopening
        await Future.delayed(const Duration(milliseconds: 100));

        // Open with encryption and restore data
        final encryptedBox =
            await Hive.openBox(boxName, encryptionCipher: cipher);
        await encryptedBox.putAll(data);
      } catch (e) {
        // If both failed, just delete and start fresh (worst case)
        // Make sure box is closed first
        if (Hive.isBoxOpen(boxName)) {
          try {
            await Hive.box(boxName).close();
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (_) {
            // Ignore close errors
          }
        }
        
        try {
          await Hive.deleteBoxFromDisk(boxName);
        } catch (_) {
          // Ignore delete errors if box doesn't exist
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        await Hive.openBox(boxName, encryptionCipher: cipher);
      }
    }
  }
}
