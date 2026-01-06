import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../injection_container.dart';
import '../bloc/ar_view_bloc.dart';
import '../widgets/ar_camera_view.dart';
import '../widgets/ar_camera_live.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({Key? key}) : super(key: key);

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  late ARViewBloc _arViewBloc;
  bool _useLiveCamera = true; // Cambiar entre vista simulada y en vivo

  @override
  void initState() {
    super.initState();
    _arViewBloc = sl<ARViewBloc>();
    _arViewBloc.add(const InitializeARViewEvent());
  }

  @override
  void dispose() {
    if (!_arViewBloc.isClosed) {
      _arViewBloc.add(const StopARViewEvent());
    }
    _arViewBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocProvider<ARViewBloc>(
        create: (_) => _arViewBloc,
        child: BlocBuilder<ARViewBloc, ARViewState>(
          builder: (context, state) {
            if (state is ARViewLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              );
            } else if (state is ARViewError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              );
            } else if (state is ARViewReady) {
              print('[AR PAGE] Rendering ARViewReady: userLocation=${state.userLocation}, nearestBusStop=${state.nearestBusStop?.name}');
              return Stack(
                children: [
                  // Vista AR principal - Elegir entre cámara en vivo o simulada
                  if (_useLiveCamera)
                    ARCameraLive(
                      userLocation: state.userLocation,
                      nearbyBuses: state.nearbyBuses,
                      nearestBusStop: state.nearestBusStop,
                    )
                  else
                    ARCameraView(
                      userLocation: state.userLocation,
                      nearbyBuses: state.nearbyBuses,
                      nearestBusStop: state.nearestBusStop,
                    ),

                  // Barra superior con botones
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: Colors.black.withOpacity(0.5),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                _useLiveCamera ? 'AR Real (Cámara)' : 'AR Simulado',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _useLiveCamera
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                                color: _useLiveCamera
                                    ? Colors.greenAccent
                                    : Colors.cyan,
                              ),
                              tooltip: 'Cambiar vista',
                              onPressed: () {
                                setState(() {
                                  _useLiveCamera = !_useLiveCamera;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.cyan,
                              ),
                              onPressed: () {
                                _showARInfoDialog(context, state);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Panel de información del paradero más cercano
                  if (state.nearestBusStop != null)
                    Positioned(
                      top: 120,
                      left: 16,
                      right: 16,
                      child: _buildNearestBusStopCard(state.nearestBusStop!),
                    ),

                  // Panel de información lateral
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: _buildBusListPanel(state),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBusListPanel(ARViewReady state) {
    if (state.nearbyBuses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              'No hay autobuses cercanos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.4,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyan, width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.cyan.withOpacity(0.5),
                  ),
                ),
              ),
              child: const Text(
                'Autobuses Cercanos',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ...state.nearbyBuses.map((bus) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.cyan.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bus ${bus.busNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      bus.routeName,
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(bus.distance / 1000).toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '${bus.speed.toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            color: Colors.lightGreen,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNearestBusStopCard(dynamic busStop) {
    // Calcular distancia aproximada
    double distance = 0;
    if (_arViewBloc.state is ARViewReady) {
      final state = _arViewBloc.state as ARViewReady;
      if (state.userLocation != null) {
        // Implementar cálculo de Haversine simplificado
        const earthRadiusKm = 6371;
        final dLat = _degreesToRadians(busStop.latitude - state.userLocation!.latitude);
        final dLng = _degreesToRadians(busStop.longitude - state.userLocation!.longitude);
        
        final a = (dLat / 2) * (dLat / 2) +
            (dLng / 2) * (dLng / 2);
        final c = 2 * (a.abs());
        distance = earthRadiusKm * c * 1000; // en metros
      }
    }

    final isVeryClose = distance < 100; // Menos de 100 metros

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isVeryClose
              ? [Colors.green.shade700, Colors.green.shade900]
              : [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVeryClose ? Colors.greenAccent : Colors.cyan,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isVeryClose ? Colors.green : Colors.cyan)
                .withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVeryClose ? Icons.location_on : Icons.directions_bus_filled,
                color: isVeryClose ? Colors.greenAccent : Colors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🚏 ${busStop.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isVeryClose)
                      const Text(
                        '¡PARADERO MUY CERCANO!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${distance.toStringAsFixed(0)} m',
                      style: TextStyle(
                        color: isVeryClose ? Colors.greenAccent : Colors.cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Distancia',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white30,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      busStop.routes.length.toString(),
                      style: const TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Rutas',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rutas: ${busStop.routes.join(", ")}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  void _showARInfoDialog(BuildContext context, ARViewReady state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Información AR',
          style: TextStyle(color: Colors.cyan),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cómo usar:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Los círculos azules representan autobuses cercanos\n'
              '• El tamaño depende de la distancia\n'
              '• La brújula muestra tu orientación\n'
              '• Los números indican velocidad y ruta\n'
              '• Gira tu dispositivo para ver los autobuses',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Autobuses cercanos: ${state.nearbyBuses.length}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state.userLocation != null)
              Text(
                'Precisión: ${state.userLocation!.accuracy.toStringAsFixed(1)} m',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
