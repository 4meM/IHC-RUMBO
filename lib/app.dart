import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RUMBO - Transporte Arequipa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// GoRouter Configuration
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('RUMBO - Home\n\nConfigurar rutas aquí'),
        ),
      ),
    ),
    // TODO: Agregar rutas de cada feature
    // - /login
    // - /register
    // - /search
    // - /map
    // - /assistant
    // - /community
  ],
);
