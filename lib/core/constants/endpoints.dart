import 'package:flutter_dotenv/flutter_dotenv.dart';

class Endpoints {
  static String get webDomain =>
      dotenv.get('WEB_DOMAIN', fallback: 'https://bbmeet.site');
  static String get baseUrl =>
      dotenv.get('API_URL', fallback: 'https://api.bbmeet.site');
  // Media server URL for WebRTC signalling
  static String get mediaUrl =>
      dotenv.get('MEDIA_URL', fallback: 'https://media.bbmeet.site');
  static const String suffixUrl = '/';
}
