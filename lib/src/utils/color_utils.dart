import 'package:flutter/material.dart';

Color parseColor(String hex) {
  var value = hex.toUpperCase().replaceAll('#', '');
  if (value.length == 6) {
    value = 'FF$value';
  }
  return Color(int.parse(value, radix: 16));
}
