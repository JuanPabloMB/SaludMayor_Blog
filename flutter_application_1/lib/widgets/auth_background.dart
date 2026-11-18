import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {

  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color.fromARGB(255, 40, 104, 141),
            Color.fromARGB(255, 154, 185, 231),
            Color.fromARGB(255, 10, 137, 255),
            Color(0xFFE8DFFF),
          ],
        ),
      ),

      child: child,
    );
  }
}