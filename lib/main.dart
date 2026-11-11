import 'package:flutter/material.dart';
import 'screens/mapa_eventos_page.dart';

void main() => runApp(const EventosApp());

class EventosApp extends StatelessWidget {
  const EventosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventos Cercanos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const MapaEventosPage(),
    );
  }
}
