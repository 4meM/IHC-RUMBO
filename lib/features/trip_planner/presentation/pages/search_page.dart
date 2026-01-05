// Página: Buscar ruta
import 'package:flutter/material.dart';
import '../widgets/map_preview.dart';
import '../../../ar_view/presentation/widgets/ar_view_fab.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MapPreview(), // Aquí se muestra el mapa directamente
      floatingActionButton: ARViewFAB(),
    );
  }
}