import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Tutaj będzie logowanie',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
