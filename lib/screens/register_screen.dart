import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:techaccord/services/api_service.dart';

class StudentRegisterPage extends StatefulWidget {
  @override
  State<StudentRegisterPage> createState() => _StudentRegisterPageState();
}

class _StudentRegisterPageState extends State<StudentRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _enrollmentYearController = TextEditingController();

  bool _loading = false;
  String _error = '';
  File? _profileImage;

  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;
  String? _programError;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    try {
      List<Map<String, dynamic>> programs = await fetchPrograms();
      setState(() {
        _programs = programs;
      });
    } catch (e) {
      setState(() {
        _programError = 'Failed to load programs';
      });
    }
  }

  Future<void> _pickProfilePicture() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProgramId == null) {
      setState(() {
        _programError = 'Please select a program';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await studentRegisterWithProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      programId: _selectedProgramId!,
      enrollmentYear: _enrollmentYearController.text.trim(),
      profilePicture: _profileImage,
    );

    setState(() {
      _loading = false;
      _error = result['message'] ?? '';
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration successful. Please verify your email.")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
Widget build(BuildContext context) {
  final primaryColor = const Color(0xFF004aad);

  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
      title: Text(
        "Student Registration",
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo and Title
                Icon(Icons.school, color: primaryColor, size: 64),
                const SizedBox(height: 12),
                Text(
                  'Student Registration',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Picture Picker
                GestureDetector(
                  onTap: _pickProfilePicture,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Icon(Icons.add_a_photo, size: 40, color: primaryColor)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined),
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) =>
                      value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) =>
                      value!.length < 6 ? 'Minimum 6 characters required' : null,
                ),
                const SizedBox(height: 16),

                // Program Dropdown
                _programs.isEmpty
                    ? (_programError != null
                        ? Text(_programError!, style: const TextStyle(color: Colors.red))
                        : const Center(child: CircularProgressIndicator()))
                    : DropdownButtonFormField<String>(
                        value: _selectedProgramId,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.school),
                          labelText: 'Select Program',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _programs.map((program) {
                          return DropdownMenuItem<String>(
                            value: program['program_id'].toString(),
                            child: Text(program['program_name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProgramId = value;
                            _programError = null;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a program' : null,
                      ),
                const SizedBox(height: 16),

                // Enrollment Year
                TextFormField(
                  controller: _enrollmentYearController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.date_range),
                    labelText: 'Enrollment Year',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message
                if (_error.isNotEmpty)
                  Text(
                    _error,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

}
