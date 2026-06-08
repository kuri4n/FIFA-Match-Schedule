import 'package:flutter/material.dart';

class PageTransitions {
  static Route fadeSlide(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.1, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOut;

        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));

        final offsetAnimation = animation.drive(tween);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
    );
  }
}