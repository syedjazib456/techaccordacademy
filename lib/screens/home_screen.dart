import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:techaccord/screens/view_course_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>>? unpaidEnrollments;
  late Future<List<dynamic>> featuredCourses;
  late Future<List<dynamic>> featuredInstructors;
  late Future<List<Map<String, dynamic>>> allCourses;
  Future<List<Map<String, dynamic>>>? enrolledCourses;
  String? userName;
  String? userProfilePic;
  String? profilePictureUrl;
  // @override
  // void initState() {
  //   super.initState();
  //   loadUserInfo();
  //   featuredCourses = fetchFeaturedCourses();
  //   featuredInstructors = fetchInstructors();
  //   allCourses = fetchAllCourseCatalog();
  //   _loadEnrolledCoursesIfLoggedIn();
  // }
  
  bool isLoggedIn = false;
  @override
void initState() {
  super.initState();
  checkLoginStatus().then((_) {
    if (isLoggedIn) {
      loadUserInfo();
      featuredCourses = fetchFeaturedCourses();
      featuredInstructors = fetchInstructors();
      allCourses = fetchAllCourseCatalog();
      _loadEnrolledCoursesIfLoggedIn();
    } else {
      featuredCourses = fetchFeaturedCourses();
      featuredInstructors = fetchInstructors();
      allCourses = fetchAllCourseCatalog();
    }
  });
}
List<Map<String, dynamic>>? snapshotEnrolledCourses;
bool isUserEnrolledInCourse(int courseCatalogId) {
  if (snapshotEnrolledCourses == null) return false;
  return snapshotEnrolledCourses!.any((course) =>
      course['course_catalog_id'].toString() == courseCatalogId.toString() &&
      course['payment_status'] == 'paid');
}


Future<void> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  setState(() {
    isLoggedIn = token != null;
  });
}
Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name');
      userProfilePic = prefs.getString('profile_picture');
      profilePictureUrl = "https://techaccordacademy.com/tech_accord_api/$userProfilePic";
    });
  }

 Future<void> _loadEnrolledCoursesIfLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    setState(() {
      enrolledCourses = fetchStudentEnrolledCourses();
      unpaidEnrollments = fetchUnpaidEnrollments();
    });

    // ✅ Debug print
    fetchUnpaidEnrollments().then((data) {
      print("Unpaid enrollments: $data");
    });
  }
}

  void _showEnrollmentTypeDialog(int courseId) async {
    String? selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_circle),
            title: const Text("Pre-recorded"),
            onTap: () => Navigator.pop(context, "pre-recorded"),
          ),
          ListTile(
            leading: const Icon(Icons.live_tv),
            title: const Text("Live"),
            onTap: () => Navigator.pop(context, "live"),
          ),
        ],
      ),
    );

    if (selectedType != null) {
      _enrollUserInCourse(courseId, selectedType);
    }
  }

  Future<void> _enrollUserInCourse(int courseId, String enrollmentType) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.blue.shade700,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    content: Row(
      children: const [
        Icon(Icons.info_outline, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child:Text('Please login to enroll in courses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
   action: SnackBarAction(
      label: 'Login',
      textColor: Colors.white,
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
    ),
    duration: const Duration(seconds: 4),
  ),
    
  
  
);
 
      return;
    }

    final result = await enrollInCourse(
      token: token,
      courseCatalogId: courseId,
      enrollmentType: enrollmentType,
    );

   ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.blue.shade700,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    content: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child:Text(result['message'] ?? 'Enrollment completed.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 3),
  ),
);
 

    if (result['success']) {
      setState(() {
        enrolledCourses = fetchStudentEnrolledCourses();
        unpaidEnrollments = fetchUnpaidEnrollments();
      });
    }
  }


Future<void> handlePayment(Map<String, dynamic> course) async {
  final txnIdController = TextEditingController();
  final amountController = TextEditingController(
    text: course['price']?.toString() ?? '',
  );

  // ✅ Save the parent context before the dialog
  final scaffoldContext = context;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Submit Payment"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: txnIdController,
            decoration: const InputDecoration(labelText: "Transaction ID"),
          ),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: "Amount Paid"),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final txnId = txnIdController.text.trim();
            final amountText = amountController.text.trim();

            if (txnId.isEmpty || amountText.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.blue.shade700,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    content: Row(
      children: const [
        Icon(Icons.info_outline, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Please fill in all fields',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 3),
  ),
);

              return;
            }

            double? amountPaid;
            try {
              amountPaid = double.parse(amountText);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.blue.shade700,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    content: Row(
      children: const [
        Icon(Icons.info_outline, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Invalid Amount Entered',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
    duration: const Duration(seconds: 3),
  ),
);

              return;
            }

            Navigator.of(context).pop(); // close dialog first

            try {
              final message = await submitPayment(
                courseId: int.parse(course['course_catalog_id'].toString()),
                transactionId: txnId,
                amountPaid: amountPaid,
              );

              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text(message)),
              );

              setState(() {
                enrolledCourses = fetchStudentEnrolledCourses();
                unpaidEnrollments = fetchUnpaidEnrollments();
              });
            } catch (e) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
          child: const Text("Submit"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      body: SingleChildScrollView(
        child: Column(
          children: [
           

            buildHeroSection(),
            const SizedBox(height: 10),
             if (!isLoggedIn) buildGetStartedButton(),
            sectionTitle('Featured Courses'),
            buildCoursesList(featuredCourses),
            const SizedBox(height: 24),
            sectionTitle('Featured Instructors'),
            buildInstructorsList(featuredInstructors),
            const SizedBox(height: 24),
            sectionTitle('All Courses'),
            buildAllCoursesSection(),
            const SizedBox(height: 24),
            sectionTitle('Your Enrolled Courses'),
            isLoggedIn
    ? buildEnrolledCoursesSection()
    : buildLoginPromptArea("Log in to view your enrolled courses"),

            const SizedBox(height: 24),
            sectionTitle('Your Unpaid Enrollments'),
          isLoggedIn
    ? buildUnpaidEnrollmentsSection()
    : buildLoginPromptArea("Log in to view your unpaid enrollments"),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

Widget buildGetStartedButton() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, '/login'); // 👈 adjust your login route
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 48, 138, 228),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      // icon: const Icon(Icons.login),
      label: const Text(
        "Get Started",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}

Widget buildLoginPromptArea(String message) {
  return GestureDetector(
    onTap: () {
      Navigator.pushNamed(context, '/login'); // 👈 adjust your route
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.login, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        ],
      ),
    ),
  );
}

Widget buildHeroSection() {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                ? NetworkImage(profilePictureUrl!)
                : const AssetImage('assets/user_gif.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back ",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  userName ?? "Continue your learning journey.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
         IconButton(
  onPressed: () async{
    if (isLoggedIn) {
       final updated = await Navigator.pushNamed(context, '/profile');
      if (updated == true) {
        loadUserInfo(); // ✅ Refresh user info immediately
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.blue.shade700,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    content: Row(
      children: const [
        Icon(Icons.info_outline, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Please log in to access your profile.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  action: SnackBarAction(
      label: 'Login',
      textColor: Colors.white,
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
    ),
    duration: const Duration(seconds: 4),
  ),
  
);

    }
  },
  icon: const Icon(Icons.supervisor_account, color: Color(0xFF004aad)),
  tooltip: "Edit Profile",
),

        ],
      ),
    ),
  );
}



 Widget buildAllCoursesSection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: allCourses,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No courses available.'),
        );
      }

      final courses = snapshot.data!;
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          final String imageUrl =
              'https://techaccordacademy.com/tech_accord_api/api/${course['thumbnail']}';
          final enrolled = isUserEnrolledInCourse(course['course_catalog_id']);

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (enrolled) {
                  Navigator.pushNamed(
                    context,
                    '/view_course',
                    arguments: course['course_catalog_id'].toString(),
                  );
                } else {
                  _showEnrollmentTypeDialog(course['course_catalog_id']);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 160, color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          course['description'] ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "PKR ${course['price'] ?? 'N/A'}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (enrolled) {
                                  Navigator.pushNamed(
                                    context,
                                    '/view_course',
                                    arguments: course['course_catalog_id'].toString(),
                                  );
                                } else {
                                  _showEnrollmentTypeDialog(course['course_catalog_id']);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: enrolled ? const Color.fromARGB(255, 8, 168, 160) : const Color.fromARGB(255, 117, 190, 250),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                             child: Text(
  enrolled ? "View" : "Enroll",
  style: TextStyle(
    color: enrolled ? Colors.white : Colors.white,
  ),
),

                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  Widget buildEnrolledCoursesSection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: enrolledCourses,
    builder: (context, snapshot) {
      snapshotEnrolledCourses = snapshot.data;

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('You have not enrolled in any courses yet.'),
        );
      }

      // ✅ Only include paid courses here
      final courses = snapshot.data!
          .where((course) => course['payment_status'] == 'paid')
          .toList();

      if (courses.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('You have not enrolled in any paid courses yet.'),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return ListTile(
            title: Text(course['title'] ?? ''),
            subtitle: Text("Type: ${course['enrollment_type'] ?? ''}"),
            trailing: const Chip(
              label: Text("Paid"),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    },
  );
}


  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildCoursesList(Future<List<dynamic>> future) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No courses available.');
        }
        final courses = snapshot.data!;
        return SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              final String imageUrl =
                  'https://techaccordacademy.com/tech_accord_api/api/${course['thumbnail']}';
              return Container(
                width: 220,
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      child: Image.network(
                        imageUrl,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        course['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        course['description'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildInstructorsList(Future<List<dynamic>> future) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No instructors available.');
        }
        final instructors = snapshot.data!;
        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: instructors.length,
            itemBuilder: (context, index) {
              final instructor = instructors[index];
              final String imageUrl =
                  'https://techaccordacademy.com/tech_accord_api/${instructor['profile_picture']}';
              return Container(
                width: 120,
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      instructor['name'] ?? '',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      instructor['expertise'] ?? '',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
 Widget buildUnpaidEnrollmentsSection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: unpaidEnrollments,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('You have no unpaid enrollments.'),
        );
      }

      final courses = snapshot.data!;
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          final title = course['title'] ?? 'Untitled';
          final price = course['price']?.toString() ?? 'N/A';
          final courseId = course['course_catalog_id'];

          return ListTile(
            title: Text(title),
            subtitle: Text("Price: PKR $price"),
            trailing: ElevatedButton(
              onPressed: courseId != null
                  ? () => handlePayment(course)
                  : null, // disable button if no course_id
              child: const Text("Pay"),
            ),
          );
        },
      );
    },
  );
}


}
