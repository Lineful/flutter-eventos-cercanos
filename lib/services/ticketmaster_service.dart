import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/evento.dart';

class TicketmasterService {
  // Pon aquí tu Consumer Key, o pásala con: --dart-define=TM_API_KEY=xxxx
  static const _apiKey =
      String.fromEnvironment('TM_API_KEY', defaultValue: 'wC44gLJ8guKyUKFvN0zyFGY06OBtsiAk');

  Future<List<Evento>> buscar({
    required double lat,
    required double lng,
    double radioKm = 5,
    String? ciudad,
    String? categoria,
    String? palabra,
  }) async {
    final params = <String, String>{
      'apikey': _apiKey,
      'latlong': '$lat,$lng',
      'radius': radioKm.toStringAsFixed(0),
      'unit': 'km',
      'size': '100',
      if (ciudad != null && ciudad.trim().isNotEmpty) 'city': ciudad.trim(),
      if (categoria != null && categoria.isNotEmpty) 'classificationName': categoria,
      if (palabra != null && palabra.trim().isNotEmpty) 'keyword': palabra.trim(),
    };

    final uri = Uri.https('app.ticketmaster.com', '/discovery/v2/events.json', params);
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('Error ${resp.statusCode} al consultar Ticketmaster');
    }
    return Evento.listaDesdeRespuesta(jsonDecode(resp.body) as Map<String, dynamic>);
  }
}
