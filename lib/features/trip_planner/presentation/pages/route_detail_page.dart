import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/bus_route_model.dart';
import '../../data/models/smart_bus_stop_model.dart';
import '../../data/services/smart_bus_stops_service.dart';
import '../widgets/smart_stops_ar_view.dart';

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
  late List<SmartBusStopModel> _smartStops;
  bool _showARView = false;

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
  }

  @override
  Widget build(BuildContext context) {
    if (_showARView) {
      return Scaffold(
        body: SmartStopsARView(
          stops: _smartStops,
          userLocation: widget.userLocation,
          onCloseAR: () {
            setState(() => _showARView = false);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ruta ${widget.routeRef}'),
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          // Información básica de la ruta
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                widget.routeRef,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.route.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${widget.route.coordinates.length} paradas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (widget.route.ref.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Referencia: ${widget.route.ref}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sección de paraderos inteligentes
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

          // Grid de paradas inteligentes
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 1,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              mainAxisSpacing: 12,
              children: _smartStops.map((stop) {
                return _buildSmartStopCard(stop);
              }).toList(),
            ),
          ),

          SizedBox(height: 24),

          // Botón flotante para ver en AR
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showARView = true);
                    },
                    icon: Icon(Icons.camera_alt),
                    label: Text(
                      'Ver Paraderos en AR',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Toca para ver los paraderos a través de la cámara',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSmartStopCard(SmartBusStopModel stop) {
    final typeColor = _getStopTypeColor(stop.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con tipo de parada
            Container(
              color: typeColor.withOpacity(0.1),
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        stop.type.emoji,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                        Text(
                          stop.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Razón
                    Text(
                      stop.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),

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
            ),
          ],
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
