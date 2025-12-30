import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/tracking_bottom_bar.dart';
import '../widgets/tracking_info_card.dart';

class LiveTrackingPage extends StatefulWidget {
  final String busNumber;
  final String routeName;

  const LiveTrackingPage({
    super.key,
    required this.busNumber,
    required this.routeName,
  });

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;
  bool _isSiestaMode = false;

  // Ubicación inicial (Arequipa, Perú)
  static const LatLng _initialPosition = LatLng(-16.409047, -71.537451);

  // Marcadores
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Marcador de la posición actual del usuario
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _initialPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ),
    );

    // Marcador del bus
    _markers.add(
      Marker(
        markerId: const MarkerId('bus_location'),
        position: const LatLng(-16.405, -71.535),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Bus ${widget.busNumber}'),
      ),
    );

    // Marcador del destino
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: const LatLng(-16.400, -71.530),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destino'),
      ),
    );

    // Ruta del bus
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('bus_route'),
        points: [
          _initialPosition,
          const LatLng(-16.405, -71.535),
          const LatLng(-16.400, -71.530),
        ],
        color: AppColors.primary,
        width: 5,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onChatPressed() {
    // Navegar a la pantalla de chat
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatSheet(),
    );
  }

  void _onSOSPressed() {
    // Mostrar opciones de SOS
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSOSSheet(),
    );
  }

  void _onSiestaToggled() {
    setState(() {
      _isSiestaMode = !_isSiestaMode;
    });

    if (_isSiestaMode) {
      // Activar alarma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm_on, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text('Alarma activada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      // Desactivar alarma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm_off, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text('Alarma desactivada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppColors.textSecondary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _onInfoPressed() {
    // Mostrar información del bus
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInfoSheet(),
    );
  }

  Widget _buildChatSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Chat de Pasajeros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Lista de mensajes (placeholder)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '5 pasajeros conectados',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comienza una conversación',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Campo de texto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Título con solo ícono
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
              // Opciones de emergencia - Grid de íconos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSOSIconButton(
                      icon: Icons.my_location,
                      onTap: () {
                        Navigator.pop(context);
                        _showTopNotification('Ubicación compartida', Icons.check_circle);
                      },
                    ),
                    _buildSOSIconButton(
                      icon: Icons.phone,
                      onTap: () {
                        Navigator.pop(context);
                        _showTopNotification('Llamando a emergencia', Icons.phone);
                      },
                    ),
                    _buildSOSIconButton(
                      icon: Icons.message,
                      onTap: () {
                        Navigator.pop(context);
                        _showTopNotification('Mensaje enviado', Icons.check_circle);
                      },
                    ),
                    _buildSOSIconButton(
                      icon: Icons.campaign,
                      onTap: () {
                        Navigator.pop(context);
                        _showTopNotification('Conductor notificado', Icons.check_circle);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppColors.error.withOpacity(0.2),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.error.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.error,
              size: 52,
            ),
          ),
        ),
      ),
    );
  }

  void _showTopNotification(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildInfoSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Título
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Información del Vehículo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Información
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoItem(
                    Icons.directions_bus,
                    'Número de Bus',
                    widget.busNumber,
                  ),
                  _buildInfoItem(
                    Icons.route,
                    'Ruta',
                    widget.routeName,
                  ),
                  _buildInfoItem(
                    Icons.person,
                    'Conductor',
                    'Juan Pérez',
                  ),
                  _buildInfoItem(
                    Icons.verified_user,
                    'Placa',
                    'ABC-123',
                  ),
                  _buildInfoItem(
                    Icons.people,
                    'Capacidad',
                    '40 pasajeros',
                  ),
                  _buildInfoItem(
                    Icons.accessible,
                    'Accesibilidad',
                    'Disponible',
                  ),
                  _buildInfoItem(
                    Icons.wifi,
                    'WiFi',
                    'No disponible',
                  ),
                  _buildInfoItem(
                    Icons.attach_money,
                    'Tarifa',
                    'S/ 1.50',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus ${widget.busNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Tarjeta de información superior
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TrackingInfoCard(
              arrivalTime: '03:40 PM',
              distance: '2.5 Km',
              busNumber: widget.busNumber,
            ),
          ),
          
          // Barra inferior con botones
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TrackingBottomBar(
              isSiestaMode: _isSiestaMode,
              onChatPressed: _onChatPressed,
              onSOSPressed: _onSOSPressed,
              onSiestaToggled: _onSiestaToggled,
              onInfoPressed: _onInfoPressed,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
