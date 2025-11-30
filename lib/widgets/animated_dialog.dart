import 'package:flutter/material.dart';

class AnimatedDialog extends StatelessWidget {
  final Widget child;

  const AnimatedDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOutBack,
        ),
        child: child,
      ),
    );
  }
}
