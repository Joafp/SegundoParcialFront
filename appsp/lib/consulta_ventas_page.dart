import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultaVentasPage extends StatefulWidget {
  @override
  _ConsultaVentasPageState createState() => _ConsultaVentasPageState();
}
class _ConsultaVentasPageState extends State<ConsultaVentasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Campos para filtros
  DateTime? _startDate;
  DateTime? _endDate;
  String _nombre = '';
  String _apellido = '';
  String _cedula = '';

  List<DocumentSnapshot> _ventas = [];
  List<Map<String, dynamic>> _ventasConClientes = [];

  @override
  void initState() {
    super.initState();
    _fetchVentas();
  }

  Future<void> _fetchVentas({String? nombre, String? apellido, String? cedula}) async {
    Query ventasQuery = _firestore.collection('ventas')
      .orderBy('fecha', descending: true); // Ordenar por fecha de mayor a menor

    // Aplicar filtro de fecha
    if (_startDate != null) {
      String startDateFormatted = '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
      ventasQuery = ventasQuery.where('fecha', isGreaterThanOrEqualTo: startDateFormatted);
      print("Filtro de fecha inicio: $startDateFormatted");
    }
    if (_endDate != null) {
      String endDateFormatted = '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';
      ventasQuery = ventasQuery.where('fecha', isLessThanOrEqualTo: endDateFormatted);
      print("Filtro de fecha fin: $endDateFormatted");
    }

    QuerySnapshot ventasSnapshot = await ventasQuery.get();
    List<Map<String, dynamic>> ventasConClientes = [];

    for (var venta in ventasSnapshot.docs) {
      print("Fecha de venta en documento: ${venta['fecha']}"); // Muestra la fecha de cada venta

      String idCliente = venta['idCliente'];

      // Aplicar filtro de cliente
      Query clienteQuery = _firestore.collection('clientes').where('idCliente', isEqualTo: idCliente);

      if (nombre != null && nombre.isNotEmpty) {
        clienteQuery = clienteQuery.where('nombre', isEqualTo: nombre);
      }
      if (apellido != null && apellido.isNotEmpty) {
        clienteQuery = clienteQuery.where('apellido', isEqualTo: apellido);
      }
      if (cedula != null && cedula.isNotEmpty) {
        clienteQuery = clienteQuery.where('cedula', isEqualTo: cedula);
      }

      QuerySnapshot clienteSnapshot = await clienteQuery.get();
      if (clienteSnapshot.docs.isNotEmpty) {
        DocumentSnapshot clienteDoc = clienteSnapshot.docs.first;
        ventasConClientes.add({
          'venta': venta,
          'cliente': clienteDoc.data(),
        });
      }
    }

    setState(() {
      _ventasConClientes = ventasConClientes;
    });
  }

  // Diálogo inicial para elegir el tipo de filtro
  void _showFilterOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleccionar Tipo de Filtro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDateFilterDialog();
                },
                child: Text('Filtrar por Fecha'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showClientFilterDialog();
                },
                child: Text('Filtrar por Cliente'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Diálogo para filtros de fecha
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Fecha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fecha de Venta', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            print("Fecha de inicio seleccionada: ${_startDate}"); // Imprime la fecha de inicio seleccionada
                          });
                        }
                      },
                      child: Text(_startDate == null ? 'Fecha Inicio' : '${_startDate!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _endDate = picked;
                            print("Fecha de fin seleccionada: ${_endDate}"); // Imprime la fecha de fin seleccionada
                          });
                        }
                      },
                      child: Text(_endDate == null ? 'Fecha Fin' : '${_endDate!.toLocal()}'.split(' ')[0]),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchVentas(); // Llamada para obtener ventas con el filtro aplicado
              },
              child: Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  // Diálogo para filtros de cliente
  void _showClientFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Cliente'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Nombre'),
                  onChanged: (value) => _nombre = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Apellido'),
                  onChanged: (value) => _apellido = value,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Cédula'),
                  onChanged: (value) => _cedula = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchVentas(nombre: _nombre, apellido: _apellido, cedula: _cedula); // Aplicar filtro de cliente
              },
              child: Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  // Función para quitar filtros
  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _nombre = '';
      _apellido = '';
      _cedula = '';
    });
    _fetchVentas();
  }

  void _showDetailPage(String idVenta) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetalleVentaPage(idVenta: idVenta)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consulta de Ventas'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterOptionsDialog,
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: _ventasConClientes.isNotEmpty
          ? ListView.builder(
              itemCount: _ventasConClientes.length,
              itemBuilder: (context, index) {
                var venta = _ventasConClientes[index]['venta'];
                var cliente = _ventasConClientes[index]['cliente'];

                return GestureDetector(
                  onTap: () {
                    _showDetailPage(venta.id); // Navigate to details page
                  },
                  child: Card(
                    margin: EdgeInsets.all(8.0),
                    elevation: 5, // Sombra para el efecto de elevación
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha: ${venta['fecha']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            'Total: \$${venta['total']}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          SizedBox(height: 8.0),
                          if (cliente != null) ...[
                            Text(
                              'Nombre: ${cliente['nombre']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Apellido: ${cliente['apellido']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Cédula: ${cliente['cedula']}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text('No se encontraron ventas'),
            ),
    );
  }
}



class DetalleVentaPage extends StatelessWidget {
  final String idVenta;

  DetalleVentaPage({required this.idVenta});

  Future<List<Map<String, dynamic>>> _fetchDetallesVenta() async {
    QuerySnapshot detallesQuery = await FirebaseFirestore.instance
        .collection('detalleVentas')
        .where('idVenta', isEqualTo: idVenta)
        .get();

    List<Map<String, dynamic>> detalles = [];

    for (var detalle in detallesQuery.docs) {
      int idProducto = detalle['idProducto'];

      QuerySnapshot productoQuery = await FirebaseFirestore.instance
          .collection('productos')
          .where('idProducto', isEqualTo: idProducto)
          .get();

      if (productoQuery.docs.isNotEmpty) {
        var productoDoc = productoQuery.docs.first;

        detalles.add({
          'idProducto': idProducto,
          'nombre': productoDoc['nombre'] ?? 'Nombre no disponible',
          'cantidad': detalle['cantidad'],
          'precio': detalle['precio'],
        });
      } else {
        detalles.add({
          'idProducto': idProducto,
          'nombre': 'Producto no encontrado',
          'cantidad': detalle['cantidad'],
          'precio': detalle['precio'],
        });
      }
    }

    return detalles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalles de la Venta')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDetallesVenta(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final detalles = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: detalles.length,
              itemBuilder: (context, index) {
                var detalle = detalles[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Producto: ${detalle['nombre']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text('Cantidad: ${detalle['cantidad']}'),
                            ],
                          ),
                        ),
                        Text(
                          '\$${detalle['precio'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
