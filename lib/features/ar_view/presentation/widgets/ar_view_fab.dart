import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ARViewFAB extends StatelessWidget {
  final VoidCallback? onPressed;

  const ARViewFAB({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        onPressed?.call();
        context.push('/ar-view');
      },
      icon: const Icon(Icons.camera_enhance),
      label: const Text('Vista AR'),
      tooltip: 'Ver autobuses en realidad aumentada',
    );
  }
}
