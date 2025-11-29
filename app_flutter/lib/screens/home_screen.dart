// app_flutter/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/paquete_service.dart';
import 'entrega_screen.dart'; // Crearemos esta pantalla después

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PaqueteService _paqueteService = PaqueteService();
  final AuthService _authService = AuthService();
  late Future<List<dynamic>> _paquetesFuture;

  @override
  void initState() {
    super.initState();
    _paquetesFuture = _paqueteService.fetchPaquetesAsignados();
  }

  void _logout() async {
    await _authService.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }
  
  void _iniciarEntrega(BuildContext context, Map paquete) {
    // Navegar a la pantalla de entrega, pasando los datos del paquete
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EntregaScreen(paquete: paquete),
      ),
    ).then((result) {
      // Cuando regresa de la pantalla de entrega, actualiza la lista
      if (result == true) {
        setState(() {
          _paquetesFuture = _paqueteService.fetchPaquetesAsignados();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Entregas Asignadas'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () {
             setState(() { _paquetesFuture = _paqueteService.fetchPaquetesAsignados(); });
          }),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _paquetesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay paquetes asignados pendientes.'));
          }

          final paquetes = snapshot.data!;
          return ListView.builder(
            itemCount: paquetes.length,
            itemBuilder: (context, index) {
              final paquete = paquetes[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Icon(Icons.inventory, color: Colors.blue),
                  title: Text('ID Único: ${paquete['id_unico_paquete']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Destino: ${paquete['direccion_destino']}'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () => _iniciarEntrega(context, paquete),
                ),
              );
            },
          );
        },
      ),
    );
  }
}