import 'package:flutter/material.dart';

import 'package:bb_meet/core/injection/injection_container.dart';
import 'package:bb_meet/core/utils/data_sources/base_local_data.dart';
import 'package:bb_meet/features/app/bloc/bloc.dart';
import 'package:bb_meet/features/auth/presentation/bloc/auth_bloc.dart';

class Application {
  /// [Production - Dev]
  static Future<void> initialAppLication() async {
    try {
      // Config local storage
      await BaseLocalData.initialBox();

      configureDependencies();

      AppBloc.authBloc.add(AuthStarted());
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  ///Singleton factory
  static final Application _instance = Application._internal();

  factory Application() {
    return _instance;
  }

  Application._internal();
}
