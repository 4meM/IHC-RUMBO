// Página: Buscar ruta
import 'package:flutter/material.dart';
import '../widgets/map_preview.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MapPreview(), // Aquí se muestra el mapa directamente
    );
  }
}