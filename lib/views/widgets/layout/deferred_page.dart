import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';

/// Lazily loads a Dart `deferred as` library on demand, caching the loaded
/// future so subsequent visits render synchronously without flicker.
class DeferredPage extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final WidgetBuilder builder;

  const DeferredPage({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  static final Map<Object, Future<void>> _loadedCache = {};
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadedCache.putIfAbsent(widget.loadLibrary, () => widget.loadLibrary());
  }

  void _retry() {
    _loadedCache.remove(widget.loadLibrary);
    setState(() {
      _future = _loadedCache.putIfAbsent(widget.loadLibrary, () => widget.loadLibrary());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          return widget.builder(context);
        }
        if (snapshot.hasError) {
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
      },
    );
  }
}
