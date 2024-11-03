import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentaPage extends StatefulWidget {
  @override
  _VentaPageState createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _productos = [];
  List<DocumentSnapshot> _filteredProductos = [];
  List<Map<String, dynamic>> _carrito = [];
  Map<int, String> _categorias = {}; // Cambiamos a int para el tipo correcto de idCategoria

  @override
  void initState() {
    super.initState();
    _fetchCategorias(); // Cargar las categorías primero
  }

  Future<void> _fetchCategorias() async {
    QuerySnapshot categoriasSnapshot = await _firestore.collection('categorias').get();
    setState(() {
      _categorias = {
        for (var doc in categoriasSnapshot.docs) doc['idcategoria'] as int: doc['nombre'] as String
      };
    });
    _fetchProductos(); // Una vez cargadas las categorías, cargar los productos
  }

  Future<void> _fetchProductos() async {
    QuerySnapshot querySnapshot = await _firestore.collection('productos').get();
    setState(() {
      _productos = querySnapshot.docs;
      _filteredProductos = _productos;
    });
  }

  void _filterProductos() {
    String filter = _searchController.text.toLowerCase();
    setState(() {
      _filteredProductos = _productos.where((doc) {
        int idCategoria = int.tryParse(doc['idcategoria']) ?? 0;
        String categoriaNombre = _categorias[idCategoria] ?? 'Sin categoría';
        return doc['nombre'].toLowerCase().contains(filter) ||
               categoriaNombre.toLowerCase().contains(filter);
      }).toList();
    });
  }

  void _addToCarrito(DocumentSnapshot producto, int cantidad) {
    setState(() {
      _carrito.add({
        'idProducto': producto['idProducto'],
        'nombre': producto['nombre'],
        'precio': producto['precioVenta'],
        'cantidad': cantidad,
      });
    });
  }

  void _showAddToCarritoDialog(DocumentSnapshot producto) {
    TextEditingController cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar al Carrito'),
          content: TextField(
            controller: cantidadController,
            decoration: InputDecoration(labelText: 'Cantidad'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                int cantidad = int.parse(cantidadController.text);
                _addToCarrito(producto, cantidad);
                Navigator.of(context).pop();
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkClienteAndFinalize(String cedula, String nombre, String apellido) async {
    QuerySnapshot clientQuery = await _firestore.collection('clientes').where('cedula', isEqualTo: cedula).get();
    String idCliente;
    if (clientQuery.docs.isNotEmpty) {
      idCliente = clientQuery.docs.first['idCliente'];
    } else {
      QuerySnapshot lastClientQuery = await _firestore.collection('clientes').orderBy('idCliente', descending: true).limit(1).get();
      int newIdCliente = lastClientQuery.docs.isNotEmpty ? int.parse(lastClientQuery.docs.first['idCliente']) + 1 : 1;
      await _firestore.collection('clientes').add({
        'idCliente': newIdCliente.toString(),
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
      });
      idCliente = newIdCliente.toString();
    }
    await _finalizarVenta(idCliente);
  }

  Future<void> _finalizarVenta(String idCliente) async {
    DocumentReference ventaRef = await _firestore.collection('ventas').add({
      'fecha': DateTime.now().toIso8601String().split('T').first,
      'idCliente': idCliente,
      'total': _carrito.fold<double>(0, (sum, item) => sum + ((item['cantidad'] as int) * (item['precio'] as double))),
    });

    for (var item in _carrito) {
      await _firestore.collection('detalleVentas').add({
        'idVenta': ventaRef.id,
        'idProducto': item['idProducto'],
        'cantidad': item['cantidad'],
        'precio': item['precio'],
      });
    }

    setState(() {
      _carrito.clear();
    });
  }

    void _showClientDialog() {
      TextEditingController cedulaController = TextEditingController();
      TextEditingController nombreController = TextEditingController();
      TextEditingController apellidoController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Información del Cliente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cedulaController,
                  decoration: InputDecoration(labelText: 'Cédula'),
                ),
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellidoController,
                  decoration: InputDecoration(labelText: 'Apellido'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  String cedula = cedulaController.text;
                  String nombre = nombreController.text;
                  String apellido = apellidoController.text;
                  _checkClienteAndFinalize(cedula, nombre, apellido);
                  Navigator.of(context).pop();
                },
                child: Text('Finalizar Compra'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      );
    }
  void _showCarritoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Carrito', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          content: Container(
            width: double.maxFinite, // Para que el contenedor ocupe el ancho completo
            child: SingleChildScrollView( // Hacer el contenido desplazable
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _carrito.isNotEmpty
                    ? _carrito.map((item) {
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nombre'],
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Cantidad: ${item['cantidad']}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Total: \$${item['cantidad'] * item['precio']}',
                                      style: TextStyle(color: Colors.green[600], fontSize: 16),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    // Lógica para eliminar un producto del carrito
                                    setState(() {
                                      _carrito.remove(item);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList()
                    : [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('El carrito está vacío', style: TextStyle(fontSize: 16)),
                        ),
                      ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showClientDialog();
              },
              child: Text('Finalizar Venta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Venta')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterProductos(),
              decoration: InputDecoration(
                labelText: 'Buscar producto',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Cambia el número de columnas según sea necesario
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _filteredProductos.length,
              itemBuilder: (context, index) {
                var producto = _filteredProductos[index];
                int idCategoria = int.tryParse(producto['idcategoria']) ?? 0;
                String categoriaNombre = _categorias[idCategoria] ?? 'Sin categoría';
                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Si tienes imágenes, descomenta la siguiente línea
                      // Image.network(producto['imageUrl'] ?? '', height: 100, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          producto['nombre'],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Precio: \$${producto['precioVenta']}',
                          style: TextStyle(color: Colors.green[600], fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Categoría: $categoriaNombre',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () => _showAddToCarritoDialog(producto),
                          child: Text('Agregar'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _showCarritoDialog,
            child: Text('Ver Carrito (${_carrito.length})'),
          ),
        ],
      ),
    );
  }
}

