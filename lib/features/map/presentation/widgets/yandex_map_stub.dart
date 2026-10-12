import 'package:flutter/material.dart';

class YandexMapView extends StatelessWidget {
  const YandexMapView(
      {super.key,
      required this.configuration,
      required this.onSelect,
      required this.onError});
  final Map<String, Object?> configuration;
  final ValueChanged<int> onSelect;
  final VoidCallback onError;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
