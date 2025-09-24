import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/ticket_models.dart';

class TicketLocalStore {
  TicketLocalStore(this._prefs);

  static const _key = 'afcm.cached_ticket';

  final SharedPreferences _prefs;

  Future<void> save(Ticket ticket) async {
    final jsonString = jsonEncode(ticket.toJson());
    await _prefs.setString(_key, jsonString);
  }

  Ticket? read() {
    final data = _prefs.getString(_key);
    if (data == null || data.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      return Ticket.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
