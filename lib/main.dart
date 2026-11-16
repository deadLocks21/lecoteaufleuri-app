import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le Coteau Fleuri',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color(0xFF8DD35F)),
      ),
      home: Scaffold(body: const Center(child: Text('Hello, World!'))),
    );
  }
}
