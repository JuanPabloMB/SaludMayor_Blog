import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}
