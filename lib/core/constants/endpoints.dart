import 'package:flutter_dotenv/flutter_dotenv.dart';

class Endpoints {
  static String get webDomain =>
      dotenv.get('WEB_DOMAIN', fallback: 'https://bbmeet.site');
  static String get baseUrl =>
      dotenv.get('API_URL', fallback: 'https://api.bbmeet.site');
  static const String suffixUrl = '/';
}
