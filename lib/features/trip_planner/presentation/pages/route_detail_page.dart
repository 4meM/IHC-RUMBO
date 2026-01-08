import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/bus_route_model.dart';
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/services/smart_bus_stops_service.dart';
import '../../data/services/selected_stop_storage.dart';
import '../widgets/smart_stops_ar_view.dart';
import '../widgets/start_tracking_button.dart';

/// Página de detalle de ruta con opciones de AR
class RouteDetailPage extends StatefulWidget {
  final BusRouteModel route;
  final LatLng userLocation;
  final String routeRef;

  const RouteDetailPage({
    Key? key,
    required this.route,
    required this.userLocation,
    required this.routeRef,
  }) : super(key: key);

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
    /// Devuelve la ubicación del paradero seleccionado
    LatLng get selectedStopLocation => _smartStops[_selectedStopIndex].location;
  late List<SmartBusStopModel> _smartStops;
  
  final Map<int, bool> _expandedStops = {}; // Control de expansión por índice
  int _selectedStopIndex = 0;
  // Persistencia simple en memoria para navegación entre pantallas
  // Si quieres persistencia entre sesiones, usar SharedPreferences o similar
  int? _pendingSelectedIndex;

  @override
  void initState() {
    super.initState();
    _generateSmartStops();
  }

  void _generateSmartStops() {
    _smartStops = SmartBusStopsService.generateSmartStops(
      userLocation: widget.userLocation,
      route: widget.route,
      routeRef: widget.routeRef,
    );
    // Restaurar selección guardada en memoria (si existe)
    final savedStopType = SelectedStopStorage.getSavedStopType(widget.routeRef);
    // Debug: listar stops y valor guardado
    try {
      // ignore: avoid_print
      print('[RouteDetailPage] _generateSmartStops routeRef=${widget.routeRef} saved=$savedStopType');
      for (var i = 0; i < _smartStops.length; i++) {
        // ignore: avoid_print
        print('[RouteDetailPage]  stop[$i] type=${_smartStops[i].type.name} name=${_smartStops[i].name}');
      }
    } catch (_) {}

    if (savedStopType != null) {
      final idx = _smartStops.indexWhere((s) => s.type.name == savedStopType);
      if (idx != -1) {
        _selectedStopIndex = idx;
      } else {
        _selectedStopIndex = 0;
      }
    } else {
      _selectedStopIndex = 0;
    }
  }

  Future<void> _openARView() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => SmartStopsARView(
          stops: _smartStops,
          userLocation: widget.userLocation,
          initialSelectedIndex: _selectedStopIndex,
          onSelectedIndexChanged: (index) {
            // Actualizar índice y refrescar UI para que el cambio sea visible
            if (mounted) {
              setState(() {
                _selectedStopIndex = index;
                SelectedStopStorage.setSavedStopType(widget.routeRef, _smartStops[index].type.name);
              });
            } else {
              _selectedStopIndex = index;
              SelectedStopStorage.setSavedStopType(widget.routeRef, _smartStops[index].type.name);
            }
          },
          onCloseAR: () {
            // El padre realiza el pop y retorna el índice seleccionado
            Navigator.pop(context, _selectedStopIndex);
          },
        ),
      ),
    );

    if (result != null) {
        setState(() {
        _selectedStopIndex = result;
        SelectedStopStorage.setSavedStopType(widget.routeRef, _smartStops[result].type.name);
        try {
          // ignore: avoid_print
          print('[RouteDetailPage] AR returned index=$result for routeRef=${widget.routeRef}');
        } catch (_) {}
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta ${widget.routeRef}'),
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Paraderos Recomendados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(_smartStops.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _buildSmartStopCard(_smartStops[index], index),
                  );
                }),
              ),
            ),
            SizedBox(height: 16),
            // Botón de opciones eliminado completamente
          ],
        ),
      ),
    );
  }

  Widget _buildSmartStopCard(SmartBusStopModel stop, int index) {
    final cardColor = Colors.blue[700]!; // Color único para todos los cards
    final cameraColor = Colors.cyan[600]!; // Color único para todas las cámaras
    final isExpanded = _expandedStops[index] ?? false;
    final isSelected = _selectedStopIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStopIndex = index;
          SelectedStopStorage.setSavedStopType(widget.routeRef, _smartStops[index].type.name);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey[200]!, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.blueAccent.withOpacity(0.15) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header compacto (siempre visible)
              Container(
                color: cardColor.withOpacity(0.1),
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              stop.type.emoji,
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stop.type.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cardColor,
                        ),
                      ),
                    ),
                    // Flecha de expansión
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedStops[index] = !isExpanded;
                        });
                      },
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: cardColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 8),
                    // Botón de cámara con tamaño fijo
                    InkWell(
                      onTap: () {
                        _openARView();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cameraColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido expandible
              if (isExpanded)
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del paradero
                      Text(
                        stop.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Razón
                      Text(
                        stop.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Métricas en fila
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetric(
                            icon: Icons.directions_walk,
                            label: 'Caminar',
                            value: '${stop.walkingDistance.toStringAsFixed(0)}m',
                            color: Colors.blue,
                          ),
                          _buildMetric(
                            icon: Icons.schedule,
                            label: 'Espera',
                            value: '${stop.estimatedWaitTime}min',
                            color: Colors.purple,
                          ),
                          _buildMetric(
                            icon: Icons.event_seat,
                            label: 'Asientos',
                            value: '${stop.estimatedAvailableSeats}',
                            color: Colors.green,
                          ),
                        ],
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

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStopTypeColor(SmartStopType type) {
    switch (type) {
      case SmartStopType.nearest:
        return Colors.blue;
      case SmartStopType.avoidTraffic:
        return Colors.orange;
      case SmartStopType.guaranteedSeats:
        return Colors.green;
    }
  }
}
