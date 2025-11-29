// main.dart - SOLUCIÓN COMPLETA PARA PAQUEXPRESS APP (FLUTTER WEB)

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Para abrir el mapa
import 'package:geolocator/geolocator.dart'; // Para obtener GPS
import 'package:image_picker/image_picker.dart'; // Para capturar/seleccionar foto
// NOTA: Se eliminó la importación condicional de dart:html para evitar el conflicto VoidCallback.

// -----------------------------------------------------------------------------
// 1. Configuración de la API y Modelos de Datos
// -----------------------------------------------------------------------------

// URL base de tu API de FastAPI
// USAR localhost:8000 para correr en CHROME/WEB en la misma computadora.
const String API_BASE_URL = "http://localhost:8000"; 

class AgenteInfo {
  final int idAgente;
  final String nombreAgente;
  final String accessToken;

  AgenteInfo({
    required this.idAgente,
    required this.nombreAgente,
    required this.accessToken,
  });

  factory AgenteInfo.fromJson(Map<String, dynamic> json) {
    return AgenteInfo(
      idAgente: json['id_agente'],
      nombreAgente: json['nombre_agente'],
      accessToken: json['access_token'],
    );
  }
}

class PaqueteAsignado {
  final int idPaquete;
  final String idUnicoPaquete;
  final String direccionDestino;
  final String estadoEntrega;

  PaqueteAsignado({
    required this.idPaquete,
    required this.idUnicoPaquete,
    required this.direccionDestino,
    required this.estadoEntrega,
  });

  factory PaqueteAsignado.fromJson(Map<String, dynamic> json) {
    return PaqueteAsignado(
      idPaquete: json['id_paquete'],
      idUnicoPaquete: json['id_unico_paquete'],
      direccionDestino: json['direccion_destino'],
      estadoEntrega: json['estado_entrega'],
    );
  }
}


// -----------------------------------------------------------------------------
// 2. Funciones de Servicio de API y Utilitarias
// -----------------------------------------------------------------------------

/// Lanza Google Maps para la navegación.
Future<void> launchGoogleMaps(String address) async {
  // Uso de un Uri de Maps robusto para navegación (q=query).
  final encodedAddress = Uri.encodeComponent(address);
  // URL de Google Maps para buscar por dirección
  final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

  if (await canLaunchUrl(url)) {
    // Abre en la aplicación externa/navegador
    await launchUrl(url, mode: LaunchMode.externalApplication); 
  } else {
    // Si falla al abrir
    throw 'No se pudo lanzar la aplicación de mapas para $address';
  }
}

/// Realiza la petición de login a la API.
Future<AgenteInfo> login(String email, String password) async {
  final url = Uri.parse('$API_BASE_URL/api/v1/auth/login');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    return AgenteInfo.fromJson(jsonDecode(response.body));
  } else if (response.statusCode == 401) {
    throw Exception('Credenciales de acceso inválidas.');
  } else {
    throw Exception('Error al conectar con la API: ${response.statusCode} - ${response.body}');
  }
}

/// Obtiene la lista de paquetes asignados para el agente.
Future<List<PaqueteAsignado>> getPaquetesAsignados(String accessToken) async {
  final url = Uri.parse('$API_BASE_URL/api/v1/paquetes/asignados');
  final response = await http.get(
    url,
    headers: <String, String>{
      'Authorization': 'Bearer $accessToken',
    },
  );

  if (response.statusCode == 200) {
    Iterable list = jsonDecode(response.body);
    return list.map((model) => PaqueteAsignado.fromJson(model)).toList();
  } else {
    throw Exception('Error al cargar paquetes: ${response.statusCode}');
  }
}

/// Registra la entrega con la ubicación real y una foto simulada.
Future<String> registrarEntrega({
  required int idPaquete,
  required String accessToken,
  required double latitud, 
  required double longitud, 
  required String urlFotoEvidencia, 
}) async {
  final url = Uri.parse('$API_BASE_URL/api/v1/paquetes/registrar_entrega');
  final body = jsonEncode(<String, dynamic>{
    'id_paquete': idPaquete,
    'latitud': latitud, 
    'longitud': longitud, 
    'url_foto_evidencia': urlFotoEvidencia, 
  });

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: body,
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body)['message'];
  } else {
    if (response.statusCode == 400) {
      final errorDetail = jsonDecode(response.body)['detail'];
      throw Exception('Error de datos: $errorDetail');
    }
    throw Exception('Fallo al registrar la entrega: ${response.statusCode}');
  }
}

// -----------------------------------------------------------------------------
// 3. Widgets de la Aplicación (UI)
// -----------------------------------------------------------------------------

void main() {
  runApp(const PaquexpressApp());
}

class PaquexpressApp extends StatelessWidget {
  const PaquexpressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paquexpress Agent',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// --- Pantalla de Login ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Credenciales de prueba
  final TextEditingController _emailController = TextEditingController(text: 'agente1@paquexpress.com'); 
  final TextEditingController _passwordController = TextEditingController(text: 'password123'); 
  bool _isLoading = false;
  String _errorMessage = '';

  void _performLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final agenteInfo = await login(_emailController.text, _passwordController.text);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaquetesScreen(agenteInfo: agenteInfo),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paquexpress - Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Acceso de Agentes', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _performLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Ingresar', style: TextStyle(fontSize: 18)),
                    ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// --- Pantalla de Paquetes Asignados ---
// -----------------------------------------------------------------------------

class PaquetesScreen extends StatefulWidget {
  final AgenteInfo agenteInfo;
  const PaquetesScreen({super.key, required this.agenteInfo});

  @override
  State<PaquetesScreen> createState() => _PaquetesScreenState();
}

class _PaquetesScreenState extends State<PaquetesScreen> {
  late Future<List<PaqueteAsignado>> _paquetesFuture;

  @override
  void initState() {
    super.initState();
    _paquetesFuture = _fetchPaquetes();
  }

  Future<List<PaqueteAsignado>> _fetchPaquetes() {
    return getPaquetesAsignados(widget.agenteInfo.accessToken);
  }
  
  // Muestra el diálogo de confirmación de entrega con los campos de GPS y Foto.
  void _showDeliveryDialog(PaqueteAsignado paquete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeliveryConfirmationDialog(
          paquete: paquete,
          agenteInfo: widget.agenteInfo,
          onDeliverySuccess: () {
            // Recargar la lista después de una entrega exitosa
            setState(() {
              _paquetesFuture = _fetchPaquetes();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paquetes de ${widget.agenteInfo.nombreAgente}'),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _paquetesFuture = _fetchPaquetes(); });
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<PaqueteAsignado>>(
        future: _paquetesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error.toString().replaceFirst('Exception: ', '')}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 20),
                  Text('¡No hay paquetes asignados!', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final paquete = snapshot.data![index];
                return PaqueteCard(
                  paquete: paquete,
                  onMapPressed: () => launchGoogleMaps(paquete.direccionDestino),
                  // Flujo mejorado: lanza el diálogo de confirmación
                  onDeliverPressed: () => _showDeliveryDialog(paquete), 
                );
              },
            );
          }
        },
      ),
    );
  }
}

// --- Card de Paquete Individual ---

class PaqueteCard extends StatelessWidget {
  final PaqueteAsignado paquete;
  final VoidCallback onMapPressed;
  final VoidCallback onDeliverPressed;

  const PaqueteCard({
    super.key,
    required this.paquete,
    required this.onMapPressed,
    required this.onDeliverPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '📦 Paquete: ${paquete.idUnicoPaquete}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text('Destino:', style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                Expanded(
                  child: Text(paquete.direccionDestino, style: const TextStyle(fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.directions, color: Colors.green),
                  onPressed: onMapPressed,
                  tooltip: 'Ver en Google Maps',
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Estado: ${paquete.estadoEntrega}', style: const TextStyle(fontStyle: FontStyle.italic)),
                ElevatedButton.icon(
                  onPressed: onDeliverPressed,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Paquete Entregado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// --- Nuevo Widget: Diálogo de Confirmación de Entrega (GPS + Foto) ---
// -----------------------------------------------------------------------------

class DeliveryConfirmationDialog extends StatefulWidget {
  final PaqueteAsignado paquete;
  final AgenteInfo agenteInfo;
  final VoidCallback onDeliverySuccess;

  const DeliveryConfirmationDialog({
    super.key,
    required this.paquete,
    required this.agenteInfo,
    required this.onDeliverySuccess,
  });

  @override
  State<DeliveryConfirmationDialog> createState() => _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState extends State<DeliveryConfirmationDialog> {
  Position? _location;
  XFile? _photoFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Función para obtener GPS 
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('El servicio de ubicación está deshabilitado. Por favor, actívalo.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación permanentemente denegados. Cambia la configuración.');
      } 
      
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        _location = position;
        _isLoading = false;
      });
      
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error GPS: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }


  // Función para seleccionar la foto desde el explorador de archivos (Web/Galería)
  Future<void> _pickImage() async {
    try {
      // Usar ImageSource.gallery permite seleccionar un archivo del explorador
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (image != null) {
        setState(() {
          _photoFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  // Función final de registro de entrega
  Future<void> _registerDelivery() async {
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Obtén la ubicación GPS primero.')));
      return;
    }
    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Selecciona la foto de evidencia.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // **Simulación de URL de la Foto**
      // En una aplicación real, aquí usarías un MultipartRequest para enviar el archivo _photoFile 
      // a tu FastAPI, y FastAPI lo subiría a un servicio de almacenamiento (S3, Cloudinary, etc.) 
      // y devolvería la URL. Aquí solo generamos la URL que FastAPI espera.
      final String photoUrl = 'http://storage.paquexpress.com/entregas/${widget.agenteInfo.idAgente}/pkg_${widget.paquete.idPaquete}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final message = await registrarEntrega(
        idPaquete: widget.paquete.idPaquete,
        accessToken: widget.agenteInfo.accessToken,
        latitud: _location!.latitude,
        longitud: _location!.longitude,
        urlFotoEvidencia: photoUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); // Cerrar diálogo
        widget.onDeliverySuccess(); // Notificar a la pantalla principal para recargar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallo: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Entrega: ${widget.paquete.idUnicoPaquete}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Destino: ${widget.paquete.direccionDestino}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),

            // --- 1. Botón de Ubicación GPS ---
            ListTile(
              leading: Icon(_location != null ? Icons.location_on : Icons.location_off, color: _location != null ? Colors.green : Colors.grey),
              title: Text(_location != null
                  ? 'Ubicación Obtenida (${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)})'
                  : 'Obtener Ubicación GPS'),
              trailing: _isLoading && _location == null
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _getCurrentLocation,
                    ),
              onTap: _getCurrentLocation,
            ),
            
            // --- 2. Botón de Foto de Evidencia (Abre el explorador de archivos) ---
            ListTile(
              leading: Icon(_photoFile != null ? Icons.photo_camera_back : Icons.no_photography, color: _photoFile != null ? Colors.blue : Colors.grey),
              title: Text(_photoFile != null
                  ? 'Foto Seleccionada: ${_photoFile!.name}'
                  : 'Seleccionar Foto de Evidencia'),
              trailing: IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: _pickImage,
              ),
              onTap: _pickImage,
            ),

            // Vista Previa de la Foto (Solo si hay foto seleccionada)
            if (_photoFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  // Image.network en web funciona con la ruta temporal de XFile
                  child: Image.network(_photoFile!.path, height: 100, fit: BoxFit.cover, 
                  errorBuilder: (context, error, stackTrace) => const Text('Error al cargar la vista previa de la imagen.'),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          // El botón se habilita solo si tenemos GPS y Foto
          onPressed: (_location != null && _photoFile != null && !_isLoading)
              ? _registerDelivery
              : null,
          child: _isLoading 
              ? const Text('Registrando...')
              : const Text('Completar Entrega'),
        ),
      ],
    );
  }
}