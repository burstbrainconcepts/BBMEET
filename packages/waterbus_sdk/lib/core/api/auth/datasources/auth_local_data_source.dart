import 'dart:async';
import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import 'package:waterbus_sdk/constants/storage_keys.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String? accessToken,
    required String? refreshToken,
  });
  Future<void> deleteToken();
  String get accessToken;
  String get refreshToken;
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  Box? _hiveBox;
  static final Map<String, Completer<void>> _saveOperations = {};

  /// Get the Hive box asynchronously, ensuring it's ready
  Future<Box> _getBoxAsync() async {
    // Import BaseLocalData to use getBoxAsync
    // Note: We need to import it, but since it's in a different package,
    // we'll use a different approach - wait for box to be ready
    
    // Wait for box to be open and not migrating
    int retries = 0;
    while (!Hive.isBoxOpen(StorageKeys.boxAuth) && retries < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (!Hive.isBoxOpen(StorageKeys.boxAuth)) {
      throw StateError(
        'Box ${StorageKeys.boxAuth} is not open. Ensure BaseLocalData.initialBox() is called first.',
      );
    }

    // Get and cache the box
    _hiveBox = Hive.box(StorageKeys.boxAuth);
    return _hiveBox!;
  }

  /// Get the Hive box synchronously (for getters)
  Box _getBox() {
    // Use cached box if available and still open
    if (_hiveBox != null && Hive.isBoxOpen(StorageKeys.boxAuth)) {
      return _hiveBox!;
    }

    // Check if box is open before accessing
    if (!Hive.isBoxOpen(StorageKeys.boxAuth)) {
      throw StateError(
        'Box ${StorageKeys.boxAuth} is not open. Ensure BaseLocalData.initialBox() is called first.',
      );
    }

    // Get and cache the box
    _hiveBox = Hive.box(StorageKeys.boxAuth);
    return _hiveBox!;
  }

  @override
  Future<void> saveTokens({
    required String? accessToken,
    required String? refreshToken,
  }) async {
    // Use a key to serialize save operations for the same box
    final operationKey = StorageKeys.boxAuth;
    
    // Wait for any ongoing save operation to complete
    while (_saveOperations.containsKey(operationKey)) {
      await _saveOperations[operationKey]!.future;
    }

    // Create a completer for this save operation
    final completer = Completer<void>();
    _saveOperations[operationKey] = completer;

    try {
      // Wait for box to be ready (not migrating)
      final box = await _getBoxAsync();
      
      // Double-check box is still open before writing
      if (!Hive.isBoxOpen(StorageKeys.boxAuth)) {
        throw StateError('Box closed during save operation');
      }

      // Perform the save operation
      await box.put(StorageKeys.accessToken, accessToken);
      await box.put(StorageKeys.refreshToken, refreshToken);
      
      completer.complete();
    } catch (e) {
      // If error, retry after a delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      try {
        if (Hive.isBoxOpen(StorageKeys.boxAuth)) {
          final box = Hive.box(StorageKeys.boxAuth);
          await box.put(StorageKeys.accessToken, accessToken);
          await box.put(StorageKeys.refreshToken, refreshToken);
          completer.complete();
        } else {
          completer.completeError(StateError('Box not available after retry'));
        }
      } catch (retryError) {
        completer.completeError(retryError);
      }
    } finally {
      _saveOperations.remove(operationKey);
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      final box = await _getBoxAsync();
      await box.delete(StorageKeys.accessToken);
      await box.delete(StorageKeys.refreshToken);
    } catch (e) {
      // Ignore errors during deletion if box is closing
      if (!e.toString().contains('closing') && !e.toString().contains('InvalidStateError')) {
        rethrow;
      }
    }
  }

  @override
  String get accessToken {
    try {
      final box = _getBox();
      return box.get(StorageKeys.accessToken, defaultValue: "");
    } catch (e) {
      // Return empty string if box is not available
      return "";
    }
  }

  @override
  String get refreshToken {
    try {
      final box = _getBox();
      return box.get(StorageKeys.refreshToken, defaultValue: "");
    } catch (e) {
      // Return empty string if box is not available
      return "";
    }
  }
}
