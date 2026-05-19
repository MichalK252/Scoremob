import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ulubione'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Tutaj będą ulubione drużyny',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
