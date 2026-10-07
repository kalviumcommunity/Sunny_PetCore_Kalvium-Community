import 'package:flutter/material.dart';

class SetupErrorScreen extends StatelessWidget {
  final String error;

  const SetupErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56),
              const SizedBox(height: 16),
              Text(
                'Firebase setup required',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure Firebase for this platform before signing in.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SelectableText(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}