import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/history_entry.dart';

class ApiService {
  /// The base URL for the backend API server.
  /// This should match your backend deployment URL including port number.
  ///
  /// NOTE: when running the Flutter app on an Android emulator, `localhost`
  /// refers to the emulator device. Use `ApiService.setBaseUrl('http://10.0.2.2:3000')`
  /// to point to the host machine. For web or desktop builds `http://localhost:3000`
  /// usually works. For physical devices use the machine LAN IP (e.g.
  /// `http://192.168.1.100:3000`).
  static String baseUrl = 'http://127.0.0.1:3000';  // Using IP instead of localhost

  /// Set the base URL at runtime (call early in app startup if needed).
  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  /// Ensure `baseUrl` is sensible for common platforms.
  ///
  /// If the developer didn't override the baseUrl and the app runs on an
  /// Android emulator, point to the host machine via 10.0.2.2. This is a
  /// best-effort helper to avoid the common "localhost" mistake when
  /// debugging on emulator. For physical devices you still need to call
  /// `setBaseUrl()` with your machine IP.
  static void _ensureBaseUrl() {
    // Only switch if user left the default localhost value
    if (baseUrl != 'http://localhost:3000') return;
    // kIsWeb prevents platform checks on web builds
    if (kIsWeb) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:3000';
      }
    } catch (_) {
      // ignore platform detection issues
    }
  }

  static Future<Map<String, dynamic>?> fetchStatus() async {
    _ensureBaseUrl();
    try {
      debugPrint('Fetching status from: ${Uri.parse('$baseUrl/status')}');
      final res = await http.get(Uri.parse('$baseUrl/status'));
      debugPrint('Status response: ${res.statusCode} - ${res.body}');
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        // Add temperature and humidity data if available
        if (data['temp'] != null && data['humi'] != null) {
          data['temperature'] = data['temp'];
          data['humidity'] = data['humi'];
        }
        return data;
      }
    } catch (e) {
      debugPrint('fetchStatus error: $e');
    }
    return null;
  }

  static Future<List<HistoryEntry>> fetchHistory() async {
    _ensureBaseUrl();
    try {
      debugPrint('Fetching history from: ${Uri.parse('$baseUrl/history')}');
      final res = await http.get(Uri.parse('$baseUrl/history'));
      debugPrint('History response: ${res.statusCode} - ${res.body}');
      if (res.statusCode == 200) {
        final List<dynamic> arr = jsonDecode(res.body);
        final entries = arr.map((e) => HistoryEntry.fromJson(e)).toList();
        debugPrint('Parsed ${entries.length} history entries');
        return entries;
      }
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    }
    return [];
  }

  static Future<bool> toggleDevice(String room, String fan, String light) async {
    _ensureBaseUrl();
    // The ESP32 expects control commands in the form:
    // {
    //   "<roomName>": { "light": "ON"/"OFF", "fan": "ON"/"OFF" }
    // }
    // RoomScreen passes fan and light as 'ON'/'OFF' strings.
    final payload = {
      room: {
        'light': light.toUpperCase(),
        'fan': fan.toUpperCase(),
      }
    };
    try {
      debugPrint('Toggling device with payload: ${jsonEncode(payload)}');
      final res = await http.post(Uri.parse('$baseUrl/control'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      debugPrint('toggleDevice response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('toggleDevice error: $e');
      return false;
    }
  }

  static Future<bool> addRoom(Map<String, dynamic> room) async {
    _ensureBaseUrl();
    try {
      // Keep the pin names that the ESP32 side expects: tempPin, lightPin, fanPin
      final payload = {
        'action': 'add',
        'room': {
          'name': room['name'],
          'tempPin': room['tempPin'] ?? -1,
          'lightPin': room['lightPin'] ?? -1,
          'fanPin': room['fanPin'] ?? -1,
        }
      };
      debugPrint('Adding room with payload: ${jsonEncode(payload)}');
      final res = await http.post(Uri.parse('$baseUrl/addRoom'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      debugPrint('addRoom response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('addRoom error: $e');
      return false;
    }
  }

  static Future<bool> removeRoom(String roomName) async {
    _ensureBaseUrl();
    final payload = {'roomName': roomName};
    try {
      final res = await http.post(Uri.parse('$baseUrl/removeRoom'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('removeRoom error: $e');
      return false;
    }
  }

  static Future<int> fetchTimeout() async {
    _ensureBaseUrl();
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/timeout'));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        return m['timeout'] ?? 10000;
      }
    } catch (e) {
      debugPrint('fetchTimeout error: $e');
    }
    return 10000;
  }

  /// Fetch the merged system data from backend.
  ///
  /// Assumption: server.js exposes a GET endpoint at /merge which returns a
  /// JSON object representing the merged system state. If your backend uses a
  /// different path (for example /api/merge or /system/merge), update the URL
  /// accordingly.
  /// Fetch the merged system data from backend by composing existing
  /// endpoints exposed in `server.js`.
  ///
  /// This does NOT depend on a `/merge` endpoint on the server. Instead it
  /// fetches `/status` (the esp32Status object) and `/api/status` (health
  /// / freshness info) and returns a combined map. If `includeHistory` is
  /// true it will also include the result of `/history` under the `history`
  /// key (this performs an extra request).
  static Future<Map<String, dynamic>?> fetchMergedSystem({
    bool includeHistory = false,
  }) async {
    _ensureBaseUrl();
    try {
      // Fetch /status and /api/status in parallel
      final statusFuture = http.get(Uri.parse('$baseUrl/status'));
      final healthFuture = http.get(Uri.parse('$baseUrl/api/status'));

      final responses = await Future.wait([statusFuture, healthFuture]);

      final statusRes = responses[0];
      final healthRes = responses[1];

      Map<String, dynamic> statusData = {};
      Map<String, dynamic> healthData = {};

      if (statusRes.statusCode == 200) {
        final d = jsonDecode(statusRes.body);
        if (d is Map<String, dynamic>) {
          statusData = d;
        } else {
          statusData = {'data': d};
        }
      }

      if (healthRes.statusCode == 200) {
        final h = jsonDecode(healthRes.body);
        if (h is Map<String, dynamic>) {
          healthData = h;
        } else {
          healthData = {'data': h};
        }
      }

      final merged = <String, dynamic>{
        'status': statusData,
        'health': healthData,
      };

      if (includeHistory) {
        final hist = await fetchHistory();
        // HistoryEntry has no toJson; convert fields manually
        merged['history'] = hist
            .map((e) => {
                  'room': e.room,
                  'timestamp': e.timestamp.toIso8601String(),
                  'voltage': e.voltage,
                  'current': e.current,
                  'power': e.power,
                  'temp': e.temp,
                  'humi': e.humi,
                })
            .toList();
      }

      // Also expose a convenience boolean indicating staleness from health
      if (healthData.isNotEmpty) merged['isStale'] = (healthData['status'] == 'stale');

      return merged;
    } catch (e) {
      debugPrint('fetchMergedSystem error: $e');
    }
    return null;
  }

  /// Subscribe to merged system updates using simple polling.
  ///
  /// This returns a Stream that polls `fetchMergedSystem` periodically and
  /// yields new results. By default it polls every 5 seconds. You can supply
  /// a different interval or use `fetchTimeout()` to pull backend timeout.
  static Stream<Map<String, dynamic>> subscribeMergedSystem({
    Duration? interval,
    bool includeHistory = false,
  }) async* {
    _ensureBaseUrl();
    int ms;
    if (interval != null) {
      ms = interval.inMilliseconds;
    } else {
      try {
        ms = await fetchTimeout();
      } catch (_) {
        ms = 5000;
      }
    }
    final actualInterval = Duration(milliseconds: ms);
    while (true) {
      final m = await fetchMergedSystem(includeHistory: includeHistory);
      if (m != null) yield m;
      await Future.delayed(actualInterval);
    }
  }

  /// Optional: send a merge request to backend. If your server expects a POST
  /// to trigger a merge operation use this. Assumes POST /merge accepts JSON.
  static Future<bool> postMergeRequest(Map<String, dynamic> payload) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/merge'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('postMergeRequest error: $e');
      return false;
    }
  }
}