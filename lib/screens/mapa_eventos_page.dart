import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/evento.dart';
import '../services/ticketmaster_service.dart';

class MapaEventosPage extends StatefulWidget {
  const MapaEventosPage({super.key});

  @override
  State<MapaEventosPage> createState() => _MapaEventosPageState();
}

class _MapaEventosPageState extends State<MapaEventosPage> {
  static const _categorias = ['', 'Music', 'Sports', 'Arts & Theatre', 'Film', 'Miscellaneous'];

  final _mapa = MapController();
  final _servicio = TicketmasterService();
  final _ciudadCtrl = TextEditingController();
  final _palabraCtrl = TextEditingController();

  LatLng? _usuario;
  List<Evento> _eventos = [];
  String _categoria = '';
  double _radioKm = 5;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  @override
  void dispose() {
    _ciudadCtrl.dispose();
    _palabraCtrl.dispose();
    super.dispose();
  }

  Future<Position> _obtenerUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('El GPS está desactivado. Actívalo e inténtalo de nuevo.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw Exception('Permiso de ubicación denegado.');
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Permiso denegado permanentemente. Habilítalo en los ajustes del dispositivo.');
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _iniciar() async {
    try {
      final pos = await _obtenerUbicacion();
      _usuario = LatLng(pos.latitude, pos.longitude);
      _mapa.move(_usuario!, 13);
      await _buscar();
    } catch (e) {
      _mensaje(e);
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _buscar() async {
    final u = _usuario;
    if (u == null) return;
    setState(() => _cargando = true);
    try {
      final eventos = await _servicio.buscar(
        lat: u.latitude,
        lng: u.longitude,
        radioKm: _radioKm,
        ciudad: _ciudadCtrl.text,
        categoria: _categoria,
        palabra: _palabraCtrl.text,
      );
      if (!mounted) return;
      setState(() => _eventos = eventos);
      if (eventos.isEmpty) _mensaje('No se encontraron eventos con esos filtros.');
    } catch (e) {
      _mensaje(e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(Object e) {
    if (!mounted) return;
    final texto = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _detalle(Evento ev) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ev.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Text('Fecha: ${ev.fecha}'),
            Text('Horario: ${ev.hora}'),
            Text('Estado: ${ev.estado}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('IR AHORA'),
                onPressed: ev.url.isEmpty
                    ? null
                    : () => launchUrl(Uri.parse(ev.url), mode: LaunchMode.externalApplication),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos Cercanos')),
      body: Column(
        children: [
          _filtros(),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(
                    initialCenter: _usuario ?? const LatLng(6.2442, -75.5812),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.eventos_cercanos',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final ev in _eventos)
                          Marker(
                            point: LatLng(ev.lat, ev.lng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _detalle(ev),
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ),
                        if (_usuario != null)
                          Marker(
                            point: _usuario!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_cargando) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _palabraCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Palabra clave', isDense: true, border: OutlineInputBorder()),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ciudadCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ciudad (opcional)', isDense: true, border: OutlineInputBorder()),
                  onSubmitted: (_) => _buscar(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoria,
                  isDense: true,
                  decoration: const InputDecoration(
                      labelText: 'Categoría', isDense: true, border: OutlineInputBorder()),
                  items: [
                    for (final c in _categorias)
                      DropdownMenuItem(value: c, child: Text(c.isEmpty ? 'Todas' : c)),
                  ],
                  onChanged: (v) => setState(() => _categoria = v ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<double>(
                value: _radioKm,
                items: const [5, 10, 25, 50]
                    .map((r) => DropdownMenuItem(value: r.toDouble(), child: Text('$r km')))
                    .toList(),
                onChanged: (v) => setState(() => _radioKm = v ?? 5),
              ),
              IconButton.filled(icon: const Icon(Icons.search), onPressed: _buscar),
            ],
          ),
        ],
      ),
    );
  }
}
