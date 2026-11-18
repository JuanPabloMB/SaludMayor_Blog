import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
 
class MapaPage extends StatefulWidget {
  const MapaPage({super.key});
 
  @override
  State<MapaPage> createState() => _MapaPageState();
}
 
class _MapaPageState extends State<MapaPage> {
  // Coordenadas aproximadas 
  final LatLng centroQueretaro = LatLng(20.5888, -100.3899);
 
  // Muestra información cuando el usuario toca un marcador.
  void _mostrarInformacion(String titulo, String descripcion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(descripcion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
 
  // Crea un marcador reutilizable para no repetir código.
  Marker _crearMarcador({
    required LatLng punto,
    required Color color,
    required String titulo,
    required String descripcion,
  }) {
    return Marker(
      point: punto,
      width: 50,
      height: 60,
      child: GestureDetector(
        onTap: () => _mostrarInformacion(titulo, descripcion),
        child: Icon(Icons.location_on, color: color, size: 40),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lugares de mi comunidad'), // Cambio 10
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: centroQueretaro,
          initialZoom: 14, // Cambio 15 (antes 12)
          minZoom: 3,
          maxZoom: 19,
        ),
        children: [
          // Capa que descarga y muestra los mosaicos de OpenStreetMap.
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // Cambia por el applicationId real de tu app.
            userAgentPackageName: 'com.example.app',
          ),
          // Capa de marcadores.
          MarkerLayer(
            markers: [
              _crearMarcador(
                punto: LatLng(20.5888, -100.3899),
                color: Colors.red,
                titulo: 'Centro de Querétaro',
                descripcion: 'Ubicación de referencia para la práctica.',
              ),
              _crearMarcador(
                punto: LatLng(20.6173, -100.3910),
                color: Colors.blue,
                titulo: 'Punto de interés 2',
                descripcion: 'Segundo marcador de ejemplo.',
              ),
              _crearMarcador(
                punto: LatLng(20.5790, -100.4000),
                color: Colors.purple, // Cambio 16 (antes verde)
                titulo: 'Punto de interés 3',
                descripcion: 'Tercer marcador de ejemplo.',
              ),

              _crearMarcador(
                punto: LatLng(20.5946, -100.3665),
                color: Colors.orange,
                titulo: 'Acueducto de Querétaro',
                descripcion:
                    'Monumento histórico del siglo XVIII, símbolo de la ciudad.',
              ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}