import 'dart:io';
import 'package:flutter/material.dart';

Widget? localBrandImage(String path, double size) {
  final file = File(path);
  if (!file.existsSync()) return null;
  return Image.file(file, width: size, height: size, fit: BoxFit.contain);
}
