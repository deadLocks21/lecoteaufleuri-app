import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
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
