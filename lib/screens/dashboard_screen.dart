import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboardPage extends StatefulWidget {
  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  String name = '';
  String email = '';
  String program = '';
  String enrollmentYear = '';
  String profilePicture = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Student';
      email = prefs.getString('email') ?? '';
      program = prefs.getString('program_name') ?? '';
      enrollmentYear = prefs.getString('enrollment_year') ?? '';
      profilePicture = prefs.getString('profile_picture') ?? '';
    });
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : AssetImage('assets/profile_placeholder.png')
                              as ImageProvider,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(email, style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Program Info Card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  leading: Icon(Icons.school, color: Colors.blue, size: 32),
                  title: Text(
                    program.isNotEmpty ? program : 'Program not set',
                    style: TextStyle(fontSize: 18),
                  ),
                  subtitle: Text(
                      enrollmentYear.isNotEmpty
                          ? 'Enrollment Year: $enrollmentYear'
                          : 'Enrollment year not set',
                      style: TextStyle(color: Colors.grey[600])),
                ),
              ),

              SizedBox(height: 20),

              // Quick Actions Section
              Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800])),
              SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildActionCard(
                      icon: Icons.book,
                      color: Colors.orange,
                      label: 'My Courses',
                      onTap: () {
                        // Navigate to Courses Page
                      }),
                  _buildActionCard(
                      icon: Icons.assignment,
                      color: Colors.green,
                      label: 'Assignments',
                      onTap: () {
                        // Navigate to Assignments Page
                      }),
                  _buildActionCard(
                      icon: Icons.video_library,
                      color: Colors.blue,
                      label: 'Recordings',
                      onTap: () {
                        // Navigate to Recordings Page
                      }),
                  _buildActionCard(
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                      label: 'Timetable',
                      onTap: () {
                        // Navigate to Timetable Page
                      }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
      {required IconData icon,
      required Color color,
      required String label,
      required Function() onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800])),
            ],
          ),
        ),
      ),
    );
  }
}
