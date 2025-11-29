// app_flutter/lib/screens/entrega_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Para GPS
import 'package:image_picker/image_picker.dart'; // Para Cámara
import 'package:url_launcher/url_launcher.dart'; // Para el mapa
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Para compatibilidad con Web

import '../services/paquete_service.dart';

class EntregaScreen extends StatefulWidget {
  final Map paquete;
  EntregaScreen({required this.paquete});

  @override
  _EntregaScreenState createState() => _EntregaScreenState();
}

class _EntregaScreenState extends State<EntregaScreen> {
  final PaqueteService _paqueteService = PaqueteService();
  File? _fotoEvidencia;
  Position? _ubicacionGps;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // No iniciamos GPS automáticamente en Web/Desktop para evitar errores de permisos.
    if (!kIsWeb) {
      _getGpsLocation(); 
    } else {
       // Mock de ubicación para Web/Desktop si no se requiere precisión estricta
      _ubicacionGps = Position(
        latitude: 20.640563, // Ubicación de ejemplo
        longitude: -100.466688,
        timestamp: DateTime.now(), accuracy: 0.0, altitude: 0.0, heading: 0.0, speed: 0.0, speedAccuracy: 0.0, altitudeAccuracy: 0.0, headingAccuracy: 0.0
      );
    }
  }

  // 1. Obtener la ubicación GPS (Solo para móvil/emulador)
  Future<void> _getGpsLocation() async {
    // Si es Web o Desktop, salimos, ya que el GPS es complejo de manejar ahí.
    if (kIsWeb) return; 

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS deshabilitado.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permiso de GPS denegado.')));
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _ubicacionGps = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al obtener la ubicación: $e')));
    }
  }

  // 2. Capturar Fotografía
  Future<void> _takePicture() async {
    if (kIsWeb) {
      // image_picker maneja Web diferente, usamos un placeholder para permitir avanzar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usa el selector de archivos de la Web o ejecuta en móvil.')));
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Usamos galería en Web
      
      // En Web, Image.file falla, pero la API permite obtener el path para la simulación
      if (pickedFile != null) {
          // No podemos usar File(pickedFile.path), solo confirmamos que la selección ocurrió
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Foto seleccionada. Continuando con la simulación.')));
          setState(() {
            // Usamos un placeholder File si es Web solo para que la validación pase.
            _fotoEvidencia = File('simulacion_web.jpg'); 
          });
      }
      return;
    }
    
    // Comportamiento normal en móvil
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _fotoEvidencia = File(pickedFile.path);
      });
    }
  }

  // 3. Función para abrir la dirección en Google Maps (Compatible con Web/Móvil)
  Future<void> _launchMapUrl() async {
    final address = widget.paquete['direccion_destino'];
    // Codifica la dirección y usa una URL que abre Google Maps universalmente
    final encodedAddress = Uri.encodeComponent(address); 
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(url)) {
      await launchUrl(url); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir la aplicación/pestaña de mapas para: $address')));
    }
  }

  // 4. Registrar la Entrega
  void _registrarEntrega() async {
    if (_fotoEvidencia == null || _ubicacionGps == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falta la foto de evidencia y/o la ubicación GPS.')));
      return;
    }
    
    // Simulación de URL de evidencia
    final mockUrl = 'http://api.paquexpress.com/evidencia/${widget.paquete['id_paquete']}/simulado.jpg';

    setState(() { _isLoading = true; });

    try {
      await _paqueteService.registrarEntrega(
        idPaquete: widget.paquete['id_paquete'],
        latitud: _ubicacionGps!.latitude,
        longitud: _ubicacionGps!.longitude,
        urlFotoEvidencia: mockUrl,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡Entrega registrada con éxito!')));
      Navigator.of(context).pop(true); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().split(':')[1])));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entrega: ${widget.paquete['id_unico_paquete']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Dirección:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.paquete['direccion_destino'], style: TextStyle(fontSize: 16)),
            Divider(),
            
            // Sección de Ubicación GPS
            Text('Ubicación GPS (Al momento de carga):', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            _ubicacionGps == null && !kIsWeb // Muestra spinner solo si no es web y está cargando
                ? Center(child: CircularProgressIndicator())
                : Text('Lat: ${_ubicacionGps!.latitude.toStringAsFixed(6)}, Lon: ${_ubicacionGps!.longitude.toStringAsFixed(6)}'),
            SizedBox(height: 10),

            // Visualización de dirección en mapa (1 Pts)
            Text('Visualización de Mapa:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[100],
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _launchMapUrl, 
                  icon: Icon(Icons.map),
                  label: Text('Ver Dirección en Google Maps', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300)
                  ),
                ),
              ),
            ),
            Divider(),

            // Sección de Fotografía
            Text('Evidencia de Entrega (Foto):', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Center(
              child: _fotoEvidencia == null
                  ? Text('No se ha capturado la foto.')
                  : kIsWeb
                      ? Text('Vista previa de archivo no soportada en Web.', style: TextStyle(color: Colors.orange))
                      : Image.file(_fotoEvidencia!, height: 200), // Comportamiento Móvil/Desktop
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _takePicture,
              icon: Icon(Icons.camera_alt),
              label: Text(_fotoEvidencia == null ? 'Tomar Foto de Evidencia' : 'Volver a Tomar Foto'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40)),
            ),
            SizedBox(height: 30),

            // Botón de Entrega
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _registrarEntrega,
                    icon: Icon(Icons.check_circle),
                    label: Text('PAQUETE ENTREGADO', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 60),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}