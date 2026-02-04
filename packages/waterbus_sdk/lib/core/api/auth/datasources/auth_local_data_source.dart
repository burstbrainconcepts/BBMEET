import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';

import 'package:waterbus_sdk/constants/storage_keys.dart';

abstract class AuthLocalDataSource {
  void saveTokens({
    required String? accessToken,
    required String? refreshToken,
  });
  void deleteToken();
  String get accessToken;
  String get refreshToken;
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  Box? _hiveBox;

  /// Get the Hive box, ensuring it's open first
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
  void saveTokens({
    required String? accessToken,
    required String? refreshToken,
  }) {
    try {
      final box = _getBox();
      // Check if box is ready for transactions
      if (!Hive.isBoxOpen(StorageKeys.boxAuth)) {
        throw StateError('Box is not open');
      }
      box.put(StorageKeys.accessToken, accessToken);
      box.put(StorageKeys.refreshToken, refreshToken);
    } catch (e) {
      // If box is closing or not ready, schedule async retry
      // This handles the race condition during migration
      final tokens = {'accessToken': accessToken, 'refreshToken': refreshToken};
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          if (Hive.isBoxOpen(StorageKeys.boxAuth)) {
            final box = Hive.box(StorageKeys.boxAuth);
            box.put(StorageKeys.accessToken, tokens['accessToken']);
            box.put(StorageKeys.refreshToken, tokens['refreshToken']);
          }
        } catch (_) {
          // Ignore retry errors - tokens will be saved on next successful auth
        }
      });
      // Don't throw - let the async retry handle it
      // This prevents blocking the auth flow
    }
  }

  @override
  void deleteToken() {
    try {
      final box = _getBox();
      box.delete(StorageKeys.accessToken);
      box.delete(StorageKeys.refreshToken);
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
