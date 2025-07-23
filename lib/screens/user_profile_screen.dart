import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techaccord/services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _enrollmentYearController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _expertiseController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();

  String? userProfilePic;
  String? profilePictureUrl;
  File? _pickedImage;
  bool _loading = false;
  String userType = 'student';

  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchProgramsIfStudent();
    _loadUserProfileFromServer();
  }

  Future<void> _loadUserProfileFromServer() async {
    try {
      final student = await fetchStudentProfile();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('name', student['name'] ?? '');
      await prefs.setString('profile_picture', student['profile_picture'] ?? '');
      await prefs.setString('role', student['role'] ?? '');

      if (student['student_details'] != null) {
        await prefs.setString('enrollment_year', student['student_details']['enrollment_year']?.toString() ?? '');
        await prefs.setString('program_id', student['student_details']['program_id']?.toString() ?? '');
      }

      setState(() {
        _nameController.text = student['name'] ?? '';
        userProfilePic = student['profile_picture'];
        profilePictureUrl = "https://techaccordacademy.com/tech_accord_api/$userProfilePic";
        userType = student['role'] ?? 'student';
        _enrollmentYearController.text = student['student_details']?['enrollment_year']?.toString() ?? '';
        _selectedProgramId = student['student_details']?['program_id']?.toString();
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading profile: $e', isError: true);
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      userProfilePic = prefs.getString('profile_picture');
      profilePictureUrl = "https://techaccordacademy.com/tech_accord_api/$userProfilePic";
      userType = prefs.getString('role') ?? 'student';
      _enrollmentYearController.text = prefs.getString('enrollment_year') ?? '';
      _selectedProgramId = prefs.getString('program_id');
      _bioController.text = prefs.getString('bio') ?? '';
      _expertiseController.text = prefs.getString('expertise') ?? '';
      _qualificationController.text = prefs.getString('qualification') ?? '';
    });
  }

  Future<void> _fetchProgramsIfStudent() async {
    if (userType == 'student') {
      try {
        _programs = await fetchPrograms();
        setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _pickProfilePicture() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final response = await updateUserProfile(
      name: _nameController.text.trim(),
      profilePictureFile: _pickedImage,
      userType: userType,
      enrollmentYear: userType == 'student' ? _enrollmentYearController.text.trim() : null,
      programId: userType == 'student' ? _selectedProgramId : null,
      bio: userType == 'instructor' ? _bioController.text.trim() : null,
      expertise: userType == 'instructor' ? _expertiseController.text.trim() : null,
      qualification: userType == 'instructor' ? _qualificationController.text.trim() : null,
    );

    setState(() => _loading = false);

    if (response['status'] == true) {
      await _loadUserProfileFromServer();
      _showSnackBar('Profile updated successfully');
      Navigator.pop(context, true);
    } else {
      _showSnackBar(response['message'] ?? 'Failed to update profile', isError: true);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isError ? const Color.fromARGB(255, 221, 87, 85) : const Color.fromARGB(255, 88, 107, 216),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF004aad);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfilePicture,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : (profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                          ? NetworkImage(profilePictureUrl!)
                          : const AssetImage('assets/user_gif.png')) as ImageProvider,
                  child: _pickedImage == null && (profilePictureUrl == null || profilePictureUrl!.isEmpty)
                      ? const Icon(Icons.add_a_photo, size: 36, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              if (userType == 'student') ...[
                TextFormField(
                  controller: _enrollmentYearController,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Year',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedProgramId,
                  decoration: const InputDecoration(
                    labelText: 'Select Program',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school),
                  ),
                  items: _programs.map((program) {
                    return DropdownMenuItem<String>(
                      value: program['program_id'].toString(),
                      child: Text(program['program_name']),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedProgramId = value),
                  validator: (value) => value == null ? 'Please select a program' : null,
                ),
                const SizedBox(height: 16),
              ],
              if (userType == 'instructor') ...[
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _expertiseController,
                  decoration: const InputDecoration(
                    labelText: 'Expertise',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qualificationController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _updateProfile,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: Text('Update Profile', style: GoogleFonts.inter(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:const Color.fromARGB(255, 23, 110, 182),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 240, 78, 75),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
