// Página: Buscar ruta
import 'package:flutter/material.dart';
import '../widgets/map_preview.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar la key del SearchPage para propagar a MapPreview
    // Esto fuerza la recreación completa del árbol de widgets
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: MapPreview(key: key),
      ),
    );
  }
}