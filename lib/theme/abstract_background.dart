import 'package:flutter/material.dart';

class AbstractBackground extends StatelessWidget {
  final Widget child;
  const AbstractBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // רקע אחיד ונקי ללא טשטושים או גרדיאנטים
    return child;
  }
}