import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:waterbus_sdk/utils/path_helper.dart';

import 'package:bb_meet/core/constants/storage_keys.dart';
import 'package:bb_meet/core/services/secure_storage_service.dart';

class BaseLocalData {
  static bool _isInitialized = false;
  static final Map<String, Future<void>> _openingBoxes = {};
  static final Map<String, Completer<void>> _boxLocks = {};
  static final Map<String, bool> _boxMigrating = {};

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

  /// Safely get a box, ensuring it's open first and not migrating
  static Future<Box> getBoxAsync(String boxName) async {
    // Wait for box to be ready if it's migrating
    await _waitForBoxReady(boxName);
    
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call BaseLocalData.initialBox() first.');
    }
    return Hive.box(boxName);
  }

  /// Safely get a box synchronously (use with caution - may throw if box is migrating)
  static Box getBox(String boxName) {
    if (_boxMigrating[boxName] == true) {
      throw StateError('Box $boxName is currently migrating. Use getBoxAsync() instead.');
    }
    if (!Hive.isBoxOpen(boxName)) {
      throw StateError('Box $boxName is not open. Call BaseLocalData.initialBox() first.');
    }
    return Hive.box(boxName);
  }

  /// Wait for a box to be ready (not migrating)
  static Future<void> _waitForBoxReady(String boxName) async {
    while (_boxMigrating[boxName] == true) {
      // Wait for migration to complete
      if (_boxLocks[boxName] != null) {
        await _boxLocks[boxName]!.future;
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  static Future<void> _openBox(String boxName, HiveCipher cipher) async {
    // Check if box is already open
    if (Hive.isBoxOpen(boxName)) {
      return;
    }

    // Check if another process is already opening this box
    if (_openingBoxes.containsKey(boxName)) {
      await _openingBoxes[boxName];
      if (Hive.isBoxOpen(boxName)) {
        return;
      }
    }

    // Create a completer for this box opening operation
    final completer = Completer<void>();
    _openingBoxes[boxName] = completer.future;

    try {
      // Try to open with encryption
      await Hive.openBox(boxName, encryptionCipher: cipher);
      completer.complete();
      _openingBoxes.remove(boxName);
    } catch (e) {
      // If failed, it might be unencrypted. Try to open without encryption
      try {
        // Check again if box was opened by another process
        if (Hive.isBoxOpen(boxName)) {
          completer.complete();
          _openingBoxes.remove(boxName);
          return;
        }

        // Mark box as migrating
        _boxMigrating[boxName] = true;
        final migrationCompleter = Completer<void>();
        _boxLocks[boxName] = migrationCompleter;

        final box = await Hive.openBox(boxName);
        // If successful, we need to migrate
        final Map<dynamic, dynamic> data = box.toMap();
        
        // Close the box before deleting
        await box.close();
        
        // Wait a bit to ensure the box is fully closed
        await Future.delayed(const Duration(milliseconds: 200));

        // Delete unencrypted box
        await Hive.deleteBoxFromDisk(boxName);

        // Wait a bit before reopening
        await Future.delayed(const Duration(milliseconds: 200));

        // Open with encryption and restore data
        final encryptedBox =
            await Hive.openBox(boxName, encryptionCipher: cipher);
        await encryptedBox.putAll(data);

        // Mark migration as complete
        _boxMigrating[boxName] = false;
        migrationCompleter.complete();
        _boxLocks.remove(boxName);
        completer.complete();
        _openingBoxes.remove(boxName);
      } catch (e) {
        // If both failed, just delete and start fresh (worst case)
        // Make sure box is closed first
        if (Hive.isBoxOpen(boxName)) {
          try {
            await Hive.box(boxName).close();
            await Future.delayed(const Duration(milliseconds: 200));
          } catch (_) {
            // Ignore close errors
          }
        }
        
        try {
          await Hive.deleteBoxFromDisk(boxName);
        } catch (_) {
          // Ignore delete errors if box doesn't exist
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
        await Hive.openBox(boxName, encryptionCipher: cipher);

        // Mark migration as complete
        _boxMigrating[boxName] = false;
        if (_boxLocks[boxName] != null) {
          _boxLocks[boxName]!.complete();
          _boxLocks.remove(boxName);
        }
        completer.complete();
        _openingBoxes.remove(boxName);
      }
    }
  }
}
