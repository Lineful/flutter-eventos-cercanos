class Evento {
  final String id;
  final String nombre;
  final String url;
  final String fecha;
  final String hora;
  final String estado;
  final double lat;
  final double lng;

  Evento({
    required this.id,
    required this.nombre,
    required this.url,
    required this.fecha,
    required this.hora,
    required this.estado,
    required this.lat,
    required this.lng,
  });

  /// Devuelve null si el evento no trae coordenadas (no se puede ubicar en el mapa).
  static Evento? fromJson(Map<String, dynamic> j) {
    final venues = j['_embedded']?['venues'] as List?;
    final loc = (venues != null && venues.isNotEmpty) ? venues.first['location'] : null;
    final lat = double.tryParse(loc?['latitude']?.toString() ?? '');
    final lng = double.tryParse(loc?['longitude']?.toString() ?? '');
    if (lat == null || lng == null) return null;

    final inicio = j['dates']?['start'] ?? {};
    final hora = (inicio['localTime'] ?? '') as String;

    return Evento(
      id: j['id'] ?? '',
      nombre: j['name'] ?? 'Sin nombre',
      url: j['url'] ?? '',
      fecha: inicio['localDate'] ?? 'Por definir',
      hora: hora.length >= 5 ? hora.substring(0, 5) : 'Por definir',
      estado: j['dates']?['status']?['code'] ?? 'desconocido',
      lat: lat,
      lng: lng,
    );
  }

  /// Extrae la lista desde el JSON profundo: _embedded -> events[].
  /// Si no hay resultados, Ticketmaster omite "_embedded".
  static List<Evento> listaDesdeRespuesta(Map<String, dynamic> body) {
    final eventos = body['_embedded']?['events'] as List? ?? [];
    return eventos
        .map((e) => Evento.fromJson(e as Map<String, dynamic>))
        .whereType<Evento>()
        .toList();
  }
}
