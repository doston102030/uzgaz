// Browser-only bridge; native builds use the conditional stub.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class YandexMapView extends StatefulWidget {
  const YandexMapView(
      {super.key,
      required this.configuration,
      required this.onSelect,
      required this.onError});
  final Map<String, Object?> configuration;
  final ValueChanged<int> onSelect;
  final VoidCallback onError;
  @override
  State<YandexMapView> createState() => _YandexMapViewState();
}

class _YandexMapViewState extends State<YandexMapView> {
  static int _nextId = 0;
  late final String _viewType;
  late final html.IFrameElement _frame;
  StreamSubscription<html.MessageEvent>? _messages;
  bool _ready = false;
  Timer? _timeout;
  @override
  void initState() {
    super.initState();
    _viewType = 'yandex-map-${_nextId++}';
    _timeout = Timer(const Duration(seconds: 25), widget.onError);
    _frame = html.IFrameElement()
      // The id in the fragment comes back on every message from the frame.
      ..src = Uri.base.resolve('yandex_map.html#$_viewType').toString()
      ..title = 'Yandex xaritasi'
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%';
    ui.platformViewRegistry.registerViewFactory(_viewType, (_) => _frame);
    _messages = html.window.onMessage.listen((event) {
      // dart:html wraps cross-frame windows in fresh objects without equality,
      // so `event.source` can't be compared with the frame; match the id.
      if (event.origin != html.window.location.origin) return;
      if (event.data is! String) return;
      try {
        final data = jsonDecode(event.data as String) as Map<String, dynamic>;
        if (data['id'] != _viewType) return;
        if (data['type'] == 'ready') {
          _ready = true;
          _send();
        } else if (data['type'] == 'loaded') {
          _timeout?.cancel();
        } else if (data['type'] == 'select' && data['index'] is int) {
          widget.onSelect(data['index'] as int);
        } else if (data['type'] == 'error') {
          widget.onError();
        }
      } catch (_) {/* Ignore unrelated browser messages. */}
    });
  }

  void _send() {
    _frame.contentWindow?.postMessage(
        jsonEncode({'type': 'configure', ...widget.configuration}),
        html.window.location.origin);
  }

  @override
  void didUpdateWidget(covariant YandexMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready) _send();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _messages?.cancel();
    _frame.src = 'about:blank';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
