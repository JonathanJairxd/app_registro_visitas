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

  @override
  Widget build(BuildContext context) {
    final visitorsStream =
        FirebaseFirestore.instance.collection('visitantes').orderBy('hora').snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitantes registrados'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: visitorsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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

              DateTime date = timestamp?.toDate() ?? DateTime.now();

              return ListTile(
                leading: fotoBase64.isEmpty
                    ? const CircleAvatar(child: Icon(Icons.person))
                    : CircleAvatar(
                        backgroundImage:
                            MemoryImage(base64Decode(fotoBase64)),
                      ),
                title: Text(nombre),
                subtitle: Text('$motivo\n${date.toLocal().toString().substring(0,16)}'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddVisitorPage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
