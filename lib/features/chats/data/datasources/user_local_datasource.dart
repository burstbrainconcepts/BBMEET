import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:waterbus_sdk/types/index.dart';

import 'package:bb_meet/core/constants/storage_keys.dart';

abstract class UserLocalDataSource {
  User? getUser();
  void saveUser(User user);
  void clearUser();
}

@LazySingleton(as: UserLocalDataSource)
class UserLocalDataSourceImpl implements UserLocalDataSource {
  Box? _hiveBox;

  Box get hiveBox {
    if (_hiveBox != null && Hive.isBoxOpen(StorageKeys.boxAuth)) {
      return _hiveBox!;
    }

    if (!Hive.isBoxOpen(StorageKeys.boxAuth)) {
      throw StateError(
        'Box ${StorageKeys.boxAuth} is not open. Ensure BaseLocalData.initialBox() is called first.',
      );
    }

    _hiveBox = Hive.box(StorageKeys.boxAuth);
    return _hiveBox!;
  }

  @override
  void clearUser() {
    hiveBox.delete(StorageKeys.user);
  }

  @override
  User? getUser() {
    final String? raw = hiveBox.get(StorageKeys.user);

    if (raw == null) return null;

    return User.fromJson(jsonDecode(raw));
  }

  @override
  void saveUser(User user) {
    hiveBox.put(StorageKeys.user, jsonEncode(user.toJson()));
  }
}
