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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2c5364),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2c5364),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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
    final size = MediaQuery.of(context).size;

    Widget imagePreview;
    if (kIsWeb) {
      imagePreview = _webImage == null
          ? const Text('No hay imagen seleccionada', style: TextStyle(color: Colors.white70))
          : Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  image: MemoryImage(_webImage!),
                  fit: BoxFit.cover,
                ),
              ),
            );
    } else {
      imagePreview = _imageFile == null
          ? const Text('No hay imagen seleccionada', style: TextStyle(color: Colors.white70))
          : Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
            );
    }

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f2027),
              Color(0xFF203a43),
              Color(0xFF2c5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              // Distribuir contenido verticalmente
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Agregar Visitante',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                // Formulario dentro de Expanded para ocupar espacio restante
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Nombre del visitante',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Ingrese un nombre' : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _motivoController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Motivo de la visita',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Ingrese un motivo' : null,
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDateTime == null
                                      ? 'No hay fecha y hora seleccionadas'
                                      : 'Fecha y hora:\n${_selectedDateTime!.toLocal().toString().substring(0, 16)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _pickDateTime,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2c5364),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text('Seleccionar fecha y hora'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Center(child: imagePreview),
                          const SizedBox(height: 10),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo, color: Colors.white),
                              label: const Text('Seleccionar foto',
                                  style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white70),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _saveVisitor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2c5364),
                              foregroundColor: Colors.white, 
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                            child: const Text('Guardar'),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
