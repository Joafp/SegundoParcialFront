import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriasPage extends StatefulWidget {
  @override
  _CategoriasPageState createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  final TextEditingController _filterController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _categorias = [];
  List<DocumentSnapshot> _filteredCategorias = [];

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    QuerySnapshot querySnapshot = await _firestore.collection('categorias').get();
    setState(() {
      _categorias = querySnapshot.docs;
      _filteredCategorias = _categorias;
    });
  }

  void _filterCategorias() {
    String filter = _filterController.text.toLowerCase();
    setState(() {
      _filteredCategorias = _categorias.where((doc) {
        return doc['nombre'].toLowerCase().contains(filter);
      }).toList();
    });
  }

  Future<int> getNextIdCategoria() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('categorias').get();
    int maxId = 0;

    for (var doc in querySnapshot.docs) {
      int currentId = doc['idcategoria'] as int;
      if (currentId > maxId) {
        maxId = currentId;
      }
    }

    return maxId + 1; // Sumar 1 al máximo encontrado
  }

  Future<void> _addCategoria(String nombre) async {
    int newIdCategoria = await getNextIdCategoria();
    await _firestore.collection('categorias').add({
      'idcategoria': newIdCategoria,
      'nombre': nombre,
    });
    _fetchCategorias();
  }

  Future<void> _deleteCategoria(String id) async {
    await _firestore.collection('categorias').doc(id).delete();
    _fetchCategorias();
  }

  void _showAddCategoriaDialog() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar Categoría'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Nombre de la categoría'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addCategoria(nameController.text);
                  Navigator.of(context).pop(); // Cerrar el popup
                }
              },
              child: Text('Agregar Categoría'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cerrar sin agregar
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
        title: Text('Categorías'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _filterController,
              onChanged: (value) => _filterCategorias(),
              decoration: InputDecoration(
                labelText: 'Filtrar por nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCategorias.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot categoria = _filteredCategorias[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.category, color: Colors.blueAccent),
                      title: Text(
                        categoria['nombre'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteCategoria(categoria.id),
                        color: Colors.red,
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
                onPressed: _showAddCategoriaDialog,
                child: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
