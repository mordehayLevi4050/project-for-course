import 'package:flutter/material.dart';

void main() {
  runApp(const GroupayApp());
}

class GroupayApp extends StatelessWidget {
  const GroupayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groupay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groupay'),
      ),
      body: Center(
        child: ElevatedButton(
          // No action yet; group creation will be added in a later story.
          onPressed: () {},
          child: const Text('קבוצה חדשה'),
        ),
      ),
    );
  }
}
