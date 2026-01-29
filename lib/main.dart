import 'dart:async';

import 'package:flutter/material.dart';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:bb_meet/amplifyconfiguration.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:waterbus_sdk/flutter_waterbus_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:bb_meet/core/app/application.dart';
import 'package:bb_meet/core/constants/endpoints.dart';
import 'package:bb_meet/core/utils/image_utils.dart';
import 'package:bb_meet/features/app/app.dart';
import 'package:bb_meet/features/settings/lang/language_service.dart';

void main(List<String> args) async {
  usePathUrlStrategy();
  await runZoned(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      try {
        await dotenv.load();
      } catch (e) {
        debugPrint("Failed to load .env file: $e");
      }

      GoRouter.optionURLReflectsImperativeAPIs = true;

      final List<Future> futures = [
        ImageUtils().init(),
          config: SdkConfig(
            serverConfig: ServerConfig(
              url: Endpoints.baseUrl,
              suffixUrl: Endpoints.suffixUrl,
              apiKey: 'bbmeet-general-api-key',
            ),
          ),
        ),
      ];

      final authPlugin = AmplifyAuthCognito();
      final List<AmplifyPluginInterface> plugins = [authPlugin];

      if (dotenv.env['PINPOINT_APP_ID'] != null &&
          dotenv.env['PINPOINT_APP_ID']!.isNotEmpty) {
        plugins.add(AmplifyAnalyticsPinpoint());
      }

      await Amplify.addPlugins(plugins);

      try {
        await Amplify.configure(amplifyConfig);
      } catch (e) {
        debugPrint('An error occurred configuring Amplify: $e');
      }

      await Future.wait(futures);

      await Application.initialAppLication();

      runApp(
        I18n(
          autoSaveLocale: true,
          initialLocale: LanguageService().getLocale().locale,
          supportedLocales: ['en-US'.asLocale, 'vi-VN'.asLocale],
          child: const App(),
        ),
      );

      if (WebRTC.platformIsMobile) {
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          safePrint('Flutter Error: ${details.exception}');
        };
      }
    },
  );
}
