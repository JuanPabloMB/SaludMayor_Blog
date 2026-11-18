import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppColors.background, child: child);
}
