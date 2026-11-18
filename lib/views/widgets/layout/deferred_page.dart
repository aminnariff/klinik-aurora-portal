import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';

/// Lazily loads a Dart `deferred as` library on demand, caching the loaded
/// state by [libraryKey] so subsequent visits render synchronously without
/// flicker and switching between deferred routes never invokes an unloaded
/// library's builder.
class DeferredPage extends StatefulWidget {
  final String libraryKey;
  final Future<void> Function() loadLibrary;
  final WidgetBuilder builder;

  const DeferredPage({
    super.key,
    required this.libraryKey,
    required this.loadLibrary,
    required this.builder,
  });

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  static final Set<String> _loadedKeys = {};
  static final Map<String, Future<void>> _inFlight = {};

  Object? _error;

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  @override
  void didUpdateWidget(covariant DeferredPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.libraryKey != widget.libraryKey) {
      _error = null;
      _ensureLoaded();
    }
  }

  void _ensureLoaded() {
    final key = widget.libraryKey;
    if (_loadedKeys.contains(key)) return;

    final future = _inFlight.putIfAbsent(
      key,
      () => widget.loadLibrary().timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw TimeoutException('Module load timed out. Please retry.'),
          ),
    );
    future.then((_) {
      _loadedKeys.add(key);
      _inFlight.remove(key);
      if (mounted && widget.libraryKey == key) {
        setState(() {
          _error = null;
        });
      }
    }).catchError((Object err) {
      _inFlight.remove(key);
      if (mounted && widget.libraryKey == key) {
        setState(() {
          _error = err;
        });
      }
    });
  }

  void _retry() {
    _loadedKeys.remove(widget.libraryKey);
    _inFlight.remove(widget.libraryKey);
    setState(() {
      _error = null;
    });
    _ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedKeys.contains(widget.libraryKey)) {
      return widget.builder(context);
    }

    final colors = context.appColors;
    if (_error != null) {
      return Scaffold(
        backgroundColor: colors.canvas,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, size: 40, color: colors.inkMuted),
                const SizedBox(height: 12),
                Text(
                  'Failed to load module',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your network connection and retry.',
                  style: TextStyle(fontSize: 13, color: colors.inkMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.brandPrimary,
        ),
      ),
    );
  }
}
