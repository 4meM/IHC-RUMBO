import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

const String _googleApiKey = 'AIzaSyABjCnncfqwu10vFn3BT7KWTLAewEgOl3I';

/// Buscar lugares usando Google Places Autocomplete API
/// Input: texto de búsqueda
/// Output: lista de sugerencias con place_id, descripción y coordenadas
Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
  if (query.isEmpty) return [];
  
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/autocomplete/json'
    '?input=$query'
    '&key=$_googleApiKey'
    '&components=country:pe'
    '&language=es',
  );
  
  final response = await http.get(url);
  
  if (response.statusCode != 200) {
    return [];
  }
  
  final data = json.decode(response.body);
  final predictions = data['predictions'] as List<dynamic>? ?? [];
  
  return predictions.map((prediction) {
    return {
      'place_id': prediction['place_id'] as String,
      'description': prediction['description'] as String,
    };
  }).toList();
}

/// Obtener detalles de un lugar específico (incluye coordenadas)
/// Input: place_id del lugar
/// Output: mapa con lat, lng, nombre, dirección
Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/details/json'
    '?place_id=$placeId'
    '&key=$_googleApiKey'
    '&language=es',
  );
  
  final response = await http.get(url);
  
  if (response.statusCode != 200) {
    return null;
  }
  
  final data = json.decode(response.body);
  final result = data['result'];
  
  if (result == null) return null;
  
  final location = result['geometry']['location'];
  
  return {
    'lat': location['lat'],
    'lng': location['lng'],
    'name': result['name'] ?? '',
    'address': result['formatted_address'] ?? '',
  };
}

/// Convertir place_id a coordenadas LatLng
/// Input: place_id del lugar
/// Output: LatLng o null si no se encuentra
Future<LatLng?> placeIdToLatLng(String placeId) async {
  final details = await getPlaceDetails(placeId);
  
  if (details == null) return null;
  
  return LatLng(details['lat'], details['lng']);
}

/// Buscar lugares cerca de una coordenada específica
/// Input: texto de búsqueda, ubicación de referencia, radio en metros
/// Output: lista de lugares cercanos
Future<List<Map<String, dynamic>>> searchNearbyPlaces({
  required String query,
  required LatLng location,
  int radius = 5000,
}) async {
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
    '?keyword=$query'
    '&location=${location.latitude},${location.longitude}'
    '&radius=$radius'
    '&key=$_googleApiKey'
    '&language=es',
  );
  
  final response = await http.get(url);
  
  if (response.statusCode != 200) {
    return [];
  }
  
  final data = json.decode(response.body);
  final results = data['results'] as List<dynamic>? ?? [];
  
  return results.map((place) {
    final location = place['geometry']['location'];
    return {
      'place_id': place['place_id'] as String,
      'name': place['name'] as String,
      'address': place['vicinity'] as String? ?? '',
      'lat': location['lat'],
      'lng': location['lng'],
    };
  }).toList();
}

/// Hacer geocoding inverso: convertir coordenadas a dirección
/// Input: coordenadas LatLng
/// Output: dirección formateada o null
Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json'
    '?latlng=${coordinates.latitude},${coordinates.longitude}'
    '&key=$_googleApiKey'
    '&language=es',
  );
  
  final response = await http.get(url);
  
  if (response.statusCode != 200) {
    return null;
  }
  
  final data = json.decode(response.body);
  final results = data['results'] as List<dynamic>? ?? [];
  
  if (results.isEmpty) return null;
  
  return results.first['formatted_address'] as String;
}

/// Buscar sugerencias con límite geográfico (bias hacia Arequipa)
/// Input: texto de búsqueda
/// Output: lista de sugerencias priorizando Arequipa
Future<List<Map<String, dynamic>>> searchPlacesInArequipa(String query) async {
  if (query.isEmpty) return [];
  
  // Centro de Arequipa
  const arequipaLat = -16.409047;
  const arequipaLng = -71.537451;
  
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/place/autocomplete/json'
    '?input=$query'
    '&key=$_googleApiKey'
    '&components=country:pe'
    '&location=$arequipaLat,$arequipaLng'
    '&radius=50000'
    '&language=es',
  );
  
  final response = await http.get(url);
  
  if (response.statusCode != 200) {
    return [];
  }
  
  final data = json.decode(response.body);
  final predictions = data['predictions'] as List<dynamic>? ?? [];
  
  return predictions.map((prediction) {
    return {
      'place_id': prediction['place_id'] as String,
      'description': prediction['description'] as String,
      'main_text': prediction['structured_formatting']['main_text'] as String,
      'secondary_text': prediction['structured_formatting']['secondary_text'] as String? ?? '',
    };
  }).toList();
}

/// Convertir coordenadas a dirección (Reverse Geocoding)
/// Input: LatLng con coordenadas
/// Output: String con la dirección formateada
Future<String> latLngToAddress(LatLng position) async {
  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json'
    '?latlng=${position.latitude},${position.longitude}'
    '&key=$_googleApiKey'
    '&language=es',
  );
  
  try {
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>? ?? [];
      
      if (results.isNotEmpty) {
        final address = results[0]['formatted_address'] as String;
        // Remover ", Perú" del final si existe
        return address.replaceAll(', Perú', '').replaceAll(', Peru', '');
      }
    }
  } catch (e) {
    print('Error en reverse geocoding: $e');
  }
  
  return 'Ubicación seleccionada';
}
