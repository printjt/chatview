import 'package:flutter/material.dart';

class IconScaleAnimation extends StatelessWidget {
  const IconScaleAnimation({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInToLinear,
        ),
        child: child,
      ),
      child: child,
    );
  }
}
