import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddVisitorPage extends StatefulWidget {
  const AddVisitorPage({super.key});

  @override
  State<AddVisitorPage> createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime? _selectedDateTime;
  File? _imageFile; // para móvil
  Uint8List? _webImage; // para web

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveVisitor() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona la fecha y hora')));
      return;
    }
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona una foto')));
      return;
    }

    late final List<int> imageBytes;
    if (kIsWeb) {
      imageBytes = _webImage!;
    } else {
      imageBytes = await _imageFile!.readAsBytes();
    }
    final base64Image = base64Encode(imageBytes);

    final doc = FirebaseFirestore.instance.collection('visitantes').doc();

    await doc.set({
      'nombre': _nombreController.text.trim(),
      'motivo': _motivoController.text.trim(),
      'hora': _selectedDateTime,
      'foto': base64Image,
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imagePreview;
    if (kIsWeb) {
      imagePreview = _webImage == null
          ? const Text('No hay imagen seleccionada')
          : Image.memory(_webImage!, height: 150);
    } else {
      imagePreview = _imageFile == null
          ? const Text('No hay imagen seleccionada')
          : Image.file(_imageFile!, height: 150);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Visitante')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del visitante'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                ),
                TextFormField(
                  controller: _motivoController,
                  decoration: const InputDecoration(labelText: 'Motivo de la visita'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese un motivo' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDateTime == null
                            ? 'No hay fecha y hora seleccionadas'
                            : 'Fecha y hora: ${_selectedDateTime!.toLocal().toString().substring(0,16)}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Seleccionar fecha y hora'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                imagePreview,
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text('Seleccionar foto'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveVisitor,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
