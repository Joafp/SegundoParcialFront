import 'package:appsp/categorias_page.dart';
import 'package:appsp/consulta_ventas_page.dart';
import 'package:appsp/firebase_options.dart';
import 'package:appsp/productos_page.dart';
import 'package:appsp/ventas_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App de Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
  
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Página Principal'),
      ),
      body: Container(
        color: Colors.white, // Fondo blanco
        padding: EdgeInsets.all(20.0), // Margen en toda la página
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'App de Compras',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Color del título
                ),
              ),
              SizedBox(height: 20), // Espacio entre el título y la línea
              Divider(thickness: 2, color: Colors.blueAccent), // Línea horizontal
              SizedBox(height: 20), // Espacio entre la línea y los botones
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CategoriasPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50), // Tamaño fijo para todos los botones
                  padding: EdgeInsets.symmetric(horizontal: 20), // Margen lateral
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Alinea el contenido a la izquierda
                  children: [
                    Icon(Icons.category, size: 30), // Tamaño del icono
                    SizedBox(width: 10), // Espacio entre el icono y el texto
                    Expanded( // Asegura que el texto ocupe el espacio restante
                      child: Text(
                        'Categorías',
                        textAlign: TextAlign.left, // Alinea el texto a la izquierda
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Espacio entre botones
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductosPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50), // Tamaño fijo para todos los botones
                  padding: EdgeInsets.symmetric(horizontal: 20), // Margen lateral
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Alinea el contenido a la izquierda
                  children: [
                    Icon(Icons.production_quantity_limits, size: 30), // Tamaño del icono
                    SizedBox(width: 10), // Espacio entre el icono y el texto
                    Expanded(
                      child: Text(
                        'Productos',
                        textAlign: TextAlign.left, // Alinea el texto a la izquierda
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Espacio entre botones
              ElevatedButton(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VentaPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50), // Tamaño fijo para todos los botones
                  padding: EdgeInsets.symmetric(horizontal: 20), // Margen lateral
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Alinea el contenido a la izquierda
                  children: [
                    Icon(Icons.shopping_cart, size: 30), // Tamaño del icono
                    SizedBox(width: 10), // Espacio entre el icono y el texto
                    Expanded(
                      child: Text(
                        'Venta',
                        textAlign: TextAlign.left, // Alinea el texto a la izquierda
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20), // Espacio entre botones
              ElevatedButton(
                onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConsultaVentasPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50), // Tamaño fijo para todos los botones
                  padding: EdgeInsets.symmetric(horizontal: 20), // Margen lateral
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Alinea el contenido a la izquierda
                  children: [
                    Icon(Icons.assignment, size: 30), // Tamaño del icono
                    SizedBox(width: 10), // Espacio entre el icono y el texto
                    Expanded(
                      child: Text(
                        'Consulta de ventas',
                        textAlign: TextAlign.left, // Alinea el texto a la izquierda
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
