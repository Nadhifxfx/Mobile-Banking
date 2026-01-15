import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _keyServerHost = 'server_host';
  static const String _keyMiddlewarePort = 'server_middleware_port';
  static const String _keyServicePort = 'server_service_port';
  static const String _keyUseHttps = 'server_use_https';

  static const String defaultHost = 'localhost';
  static const int defaultMiddlewarePort = 8000;
  static const int defaultServicePort = 8001;
  static const bool defaultUseHttps = false;

  static Future<String> getServerHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerHost) ?? defaultHost;
  }

  static Future<int> getMiddlewarePort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMiddlewarePort) ?? defaultMiddlewarePort;
  }

  static Future<int> getServicePort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyServicePort) ?? defaultServicePort;
  }

  static Future<bool> getUseHttps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseHttps) ?? defaultUseHttps;
  }

  static Future<void> setServerHost(String host) async {
    final normalized = _normalizeHost(host);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerHost, normalized);
  }

  static Future<void> setMiddlewarePort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMiddlewarePort, port);
  }

  static Future<void> setServicePort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyServicePort, port);
  }

  static Future<void> setUseHttps(bool useHttps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseHttps, useHttps);
  }

  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerHost, defaultHost);
    await prefs.setInt(_keyMiddlewarePort, defaultMiddlewarePort);
    await prefs.setInt(_keyServicePort, defaultServicePort);
    await prefs.setBool(_keyUseHttps, defaultUseHttps);
  }

  static Future<String> getMiddlewareBaseUrl() async {
    final host = await getServerHost();
    final port = await getMiddlewarePort();
    final scheme = (await getUseHttps()) ? 'https' : 'http';
    return '$scheme://$host:$port/api/v1';
  }

  static Future<String> getServiceLayerBaseUrl() async {
    final host = await getServerHost();
    final port = await getServicePort();
    final scheme = (await getUseHttps()) ? 'https' : 'http';
    return '$scheme://$host:$port/service';
  }

  static String _normalizeHost(String input) {
    var host = input.trim();
    host = host.replaceAll(RegExp(r'^https?://', caseSensitive: false), '');

    // remove any path/query fragments
    final slashIndex = host.indexOf('/');
    if (slashIndex != -1) {
      host = host.substring(0, slashIndex);
    }

    // if user pasted host:port, keep only host
    final colonIndex = host.lastIndexOf(':');
    if (colonIndex != -1 && !host.contains(']')) {
      // crude but fine for IPv4/hostnames
      final possiblePort = host.substring(colonIndex + 1);
      if (int.tryParse(possiblePort) != null) {
        host = host.substring(0, colonIndex);
      }
    }

    return host.isEmpty ? defaultHost : host;
  }
}
