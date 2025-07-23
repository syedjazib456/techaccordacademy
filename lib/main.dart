import 'package:flutter/material.dart';
import 'package:techaccord/screens/dashboard_screen.dart';
import 'package:techaccord/screens/home_screen.dart';
import 'package:techaccord/screens/login_screen.dart';
import 'package:techaccord/screens/register_screen.dart';
import 'package:techaccord/screens/user_profile_screen.dart';
import 'package:techaccord/screens/view_course_screen.dart';



void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tech Accord Academy',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/profile': (context) => UserProfileScreen(),
        '/login': (context) => StudentLoginPage(),
        '/register': (context) => StudentRegisterPage(),
        '/student_dashboard': (context) => StudentDashboardPage(),
        '/view_course': (context) {
  final courseCatalogId = ModalRoute.of(context)!.settings.arguments as String;
  return ViewCourseScreen(courseCatalogId: courseCatalogId);
},
      },
    );
  }
}
