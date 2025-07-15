import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_visitor_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showPhotoDialog(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitorsStream = FirebaseFirestore.instance
        .collection('visitantes')
        .orderBy('hora', descending: true)
        .snapshots();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f2027),
              Color(0xFF203a43),
              Color(0xFF2c5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Visitantes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: visitorsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text('No hay visitantes registrados'));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data()! as Map<String, dynamic>;
                          final nombre = data['nombre'] ?? '';
                          final motivo = data['motivo'] ?? '';
                          final timestamp = data['hora'] as Timestamp?;
                          final fotoBase64 = data['foto'] ?? '';

                          final date = timestamp?.toDate() ?? DateTime.now();
                          final formattedDate = "${date.toLocal().toString().substring(0, 16)}";

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: fotoBase64.isNotEmpty
                                    ? () => _showPhotoDialog(context, fotoBase64)
                                    : null,
                                child: fotoBase64.isEmpty
                                    ? const CircleAvatar(child: Icon(Icons.person))
                                    : CircleAvatar(
                                        backgroundImage: MemoryImage(base64Decode(fotoBase64)),
                                      ),
                              ),
                              title: Text(nombre),
                              subtitle: Text('$motivo\n$formattedDate'),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2c5364),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVisitorPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
