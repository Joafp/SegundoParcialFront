import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosPage extends StatefulWidget {
  @override
  _ProductosPageState createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final TextEditingController _filterController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _productos = [];
  List<DocumentSnapshot> _filteredProductos = [];
  List<DocumentSnapshot> _categorias = [];
  String? _selectedCategoriaId;

  @override
  void initState() {
    super.initState();
    _fetchProductos();
    _fetchCategorias();
  }

  Future<void> _fetchProductos() async {
    QuerySnapshot querySnapshot = await _firestore.collection('productos').get();
    setState(() {
      _productos = querySnapshot.docs;
      _filteredProductos = _productos;
    });
  }

  Future<void> _fetchCategorias() async {
    QuerySnapshot querySnapshot = await _firestore.collection('categorias').get();
    setState(() {
      _categorias = querySnapshot.docs;
    });
  }

  void _filterProductos() {
    String filter = _filterController.text.toLowerCase();
    setState(() {
      _filteredProductos = _productos.where((doc) {
        return doc['nombre'].toLowerCase().contains(filter);
      }).toList();
    });
  }

  Future<int> getNextIdProducto() async {
    QuerySnapshot querySnapshot = await _firestore.collection('productos').get();
    int maxId = 0;

    for (var doc in querySnapshot.docs) {
      int currentId = doc['idProducto'] as int;
      if (currentId > maxId) {
        maxId = currentId;
      }
    }

    return maxId + 1;
  }

  
  String getNombreCategoria(String idCategoria) {
    // Verifica si idCategoria está vacío
    if (idCategoria.isEmpty) return 'Sin categoría'; // Valor por defecto

    // Convierte idCategoria a int para la comparación
    int idCategoriaInt = int.tryParse(idCategoria) ?? -1; // -1 o cualquier otro valor que sepas que no existirá

    // Busca la categoría en la lista de categorías
    var categoria = _categorias.firstWhere(
      (cat) => cat['idcategoria'] == idCategoriaInt, // Compara como números
    );

    // Devuelve el nombre de la categoría
    return categoria['nombre'];
  }

  Future<void> _addProducto(String nombre, double precio, String? idCategoria) async {
    int newIdProducto = await getNextIdProducto();
    await _firestore.collection('productos').add({
      'idProducto': newIdProducto,
      'nombre': nombre,
      'precioVenta': precio,
      'idcategoria': idCategoria,
    });
    _fetchProductos();
  }

  Future<void> _deleteProducto(String id) async {
    await _firestore.collection('productos').doc(id).delete();
    _fetchProductos();
  }

  void _showAddProductoDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nombre del producto'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Precio de venta'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategoriaId,
                hint: Text('Seleccionar categoría'),
                items: _categorias.map((categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria['idcategoria'].toString(),
                    child: Text(categoria['nombre']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoriaId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  double? price = double.tryParse(priceController.text);
                  if (price != null) {
                    _addProducto(nameController.text, price, _selectedCategoriaId);
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Por favor, ingresa un precio válido.'),
                    ));
                  }
                }
              },
              child: Text('Agregar Producto'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _filterController,
              onChanged: (value) => _filterProductos(),
              decoration: InputDecoration(
                labelText: 'Filtrar por nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredProductos.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot producto = _filteredProductos[index];
                  String nombreCategoria = getNombreCategoria(producto['idcategoria'].toString());

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.shopping_bag, color: Colors.blueAccent),
                      title: Text(
                        producto['nombre'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Precio: \$${producto['precioVenta']} \nCategoría: $nombreCategoria',
                        style: TextStyle(height: 1.5),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProducto(producto.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: _showAddProductoDialog,
                child: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
