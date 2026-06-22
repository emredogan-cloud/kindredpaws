import 'package:flutter/material.dart';
import 'package:kindredpaws/src/build_info.dart';

void main() {
  runApp(const KindredPawsApp());
}

/// Root application widget.
///
/// NOTE: This is a *walking skeleton* used solely to validate the engineering
/// environment (build → test → screenshot → device → CI → release). It
/// deliberately contains no gameplay. Phase 0 replaces [EnvironmentCheckPage].
class KindredPawsApp extends StatelessWidget {
  const KindredPawsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C8EAD)),
      ),
      home: const EnvironmentCheckPage(),
    );
  }
}

/// Minimal screen proving the toolchain renders, themes, and handles input.
class EnvironmentCheckPage extends StatefulWidget {
  const EnvironmentCheckPage({super.key});

  @override
  State<EnvironmentCheckPage> createState() => _EnvironmentCheckPageState();
}

class _EnvironmentCheckPageState extends State<EnvironmentCheckPage> {
  int _taps = 0;

  void _increment() => setState(() => _taps++);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text(kAppName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              healthLabel(),
              key: const Key('healthcheck-banner'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('channel: $kBuildChannel', style: theme.textTheme.bodySmall),
            const SizedBox(height: 32),
            const Text('interaction self-check taps:'),
            Text(
              '$_taps',
              key: const Key('counter-text'),
              style: theme.textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('increment-fab'),
        onPressed: _increment,
        tooltip: 'Increment self-check',
        child: const Icon(Icons.add),
      ),
    );
  }
}
