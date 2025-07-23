import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
const String BASE_URL = "https://techaccordacademy.com/tech_accord_api/api/student_dashboard/";

Future<Map<String, dynamic>> studentLogin(String email, String password) async {
  const String apiUrl = "https://techaccordacademy.com/tech_accord_api/api/users/student_login.php";

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );

  final jsonData = jsonDecode(response.body);

  if (jsonData['status'] == true) {
    // Store token and details in shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', jsonData['token']);
    await prefs.setString('role', jsonData['role']);
    await prefs.setString('user_id', jsonData['user_id'].toString());
    await prefs.setString('name', jsonData['name']);
    await prefs.setString('email', jsonData['email']);
    await prefs.setString('profile_picture', jsonData['profile_picture']);
    await prefs.setString('program_name', jsonData['program_name']);
    await prefs.setString('program_id', jsonData['program_id'].toString());
    await prefs.setString('enrollment_year', jsonData['enrollment_year'].toString());

    return {"success": true, "message": "Login successful"};
  } else {
    return {"success": false, "message": jsonData['message'] ?? "Login failed"};
  }
}




Future<Map<String, dynamic>> studentRegisterWithProfile({
  required String name,
  required String email,
  required String password,
  required String programId,
  required String enrollmentYear,
  File? profilePicture, // Nullable, optional
}) async {
  final url = Uri.parse('https://techaccordacademy.com/tech_accord_api/api/users/register.php');

  try {
    final request = http.MultipartRequest('POST', url);

    // Add fields
    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['role'] = 'student';
    request.fields['program_id'] = programId;
    request.fields['enrollment_year'] = enrollmentYear;

    // Add file if provided
    if (profilePicture != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        profilePicture.path,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        return {
          "success": true,
          "message": data['message'],
          "token": data['token'],
        };
      } else {
        return {
          "success": false,
          "message": data['message'] ?? 'Registration failed',
        };
      }
    } else {
      return {
        "success": false,
        "message": "Server error: ${response.statusCode}",
      };
    }
  } catch (e) {
    return {
      "success": false,
      "message": "Error: $e",
    };
  }
}
Future<List<Map<String, dynamic>>> fetchPrograms() async {
  const String apiUrl = 'https://techaccordacademy.com/tech_accord_api/api/public/fetch_programs.php';

  try {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == true) {
        List<dynamic> programs = data['data'];
        return programs.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch programs');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching programs: $e');
  }
}
Future<List<Map<String, dynamic>>> fetchFeaturedCourses() async {
  try {
    final response = await http.get(Uri.parse("${BASE_URL}course_catalog.php"));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == true && jsonData['data'] != null) {
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        throw Exception(jsonData['message'] ?? "Failed to fetch featured courses");
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("fetchFeaturedCourses error: $e");
    rethrow;
  }
}
Future<List<Map<String, dynamic>>> fetchInstructors() async {
  try {
    final response = await http.get(Uri.parse("${BASE_URL}instructors.php"));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == true && jsonData['data'] != null) {
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        throw Exception(jsonData['message'] ?? "Failed to fetch instructors");
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("fetchInstructors error: $e");
    rethrow;
  }
}
Future<Map<String, dynamic>> enrollInCourse({
  required String token,
  required int courseCatalogId,  // actually course_catalog_id
  String enrollmentType = "pre-recorded",
}) async {
  try {
    final response = await http.post(
      Uri.parse("${BASE_URL}course_enrollment.php"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode({
        "course_id": courseCatalogId.toString(), // force to String
        "enrollment_type": enrollmentType,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData["status"] == true) {
        return {
          "success": true,
          "message": jsonData["message"]?.toString() ?? "Successfully enrolled in the course.",
        };
      } else {
        return {
          "success": false,
          "message": jsonData["message"]?.toString() ?? "Failed to enroll in the course.",
        };
      }
    } else if (response.statusCode == 401) {
      return {
        "success": false,
        "message": "Unauthorized: Please login first.",
      };
    } else {
      return {
        "success": false,
        "message": "Server error: ${response.statusCode}",
      };
    }
  } catch (e) {
    print("enrollInCourse error: $e");
    return {
      "success": false,
      "message": "An error occurred. Please try again.",
    };
  }
}

Future<List<Map<String, dynamic>>> fetchAllCourseCatalog() async {
  try {
    final response = await http.get(
      Uri.parse("${BASE_URL}all_course_catalog.php"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData["status"] == true) {
        List courses = jsonData["data"] ?? [];
        return List<Map<String, dynamic>>.from(courses);
      } else {
        throw Exception(jsonData["message"] ?? "Failed to fetch courses.");
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("fetchAllCourseCatalog error: $e");
    throw Exception("An error occurred while fetching courses.");
  }
}
Future<List<Map<String, dynamic>>> fetchStudentEnrolledCourses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

   if (token == null) {
  print("No user token found. User not logged in.");
  return []; // simply return an empty list
}

    final response = await http.get(
      Uri.parse("${BASE_URL}access_granted_courses.php"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData["status"] == true) {
        List courses = jsonData["data"] ?? [];
        return List<Map<String, dynamic>>.from(courses);
      } else {
        throw Exception(jsonData["message"] ?? "Failed to fetch enrolled courses.");
      }
    } else if (response.statusCode == 401) {
      throw Exception("Session expired. Please login again.");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("fetchStudentEnrolledCourses error: $e");
    throw Exception("An error occurred while fetching your courses.");
  }
}

Future<String> submitPayment({
  required int courseId,
  required String transactionId,
  required double amountPaid,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception("User not logged in.");
    }

    final response = await http.post(
      Uri.parse("${BASE_URL}submit_payment.php"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "course_id": courseId,
        "transaction_id": transactionId,
        "amount_paid": amountPaid,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData["status"] == true) {
        return jsonData["message"] ?? "Payment submitted successfully.";
      } else {
        throw Exception(jsonData["message"] ?? "Failed to submit payment.");
      }
    } else if (response.statusCode == 401) {
      throw Exception("Session expired. Please login again.");
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  } catch (e) {
    print("submitPayment error: $e");
    throw Exception("An error occurred while submitting your payment.");
  }
}
Future<List<Map<String, dynamic>>> fetchUnpaidEnrollments() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    throw Exception("User is not logged in.");
  }

  final response = await http.get(
    Uri.parse('https://techaccordacademy.com/tech_accord_api/api/student_dashboard/unpaid_enrollments.php'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  final jsonResponse = json.decode(response.body);

  if (response.statusCode == 200 && jsonResponse['status'] == true) {
    final List<dynamic> data = jsonResponse['data'];
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception(jsonResponse['message'] ?? 'Failed to fetch unpaid enrollments');
  }
}
Future<Map<String, dynamic>> fetchStudentProfile() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) {
    throw Exception('User not logged in.');
  }

  final url = Uri.parse('https://techaccordacademy.com/tech_accord_api/api/users/fetch_students.php');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);

    if (json['status'] == true) {
      return json['student'];
    } else {
      throw Exception(json['message'] ?? 'Failed to fetch profile');
    }
  } else {
    throw Exception('Failed to fetch profile: ${response.statusCode}');
  }
}
/// Update user profile (name, profile picture, and other user-specific data)
Future<Map<String, dynamic>> updateUserProfile({
  required String name,
  File? profilePictureFile,
  required String userType, // 'student' or 'instructor'
  String? enrollmentYear, // student-specific
  String? programId,      // student-specific
  String? bio,            // instructor-specific
  String? expertise,      // instructor-specific
  String? qualification,  // instructor-specific
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token'); // JWT stored during login
  final userId = prefs.getString('user_id'); // stored during login

  if (token == null || userId == null) {
    return {'status': false, 'message': 'User not logged in'};
  }

  try {
    final uri = Uri.parse("https://techaccordacademy.com/tech_accord_api/api/users/update_user.php");
    final request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['user_id'] = userId
      ..fields['user_type'] = userType
      ..headers['Authorization'] = 'Bearer $token';

    // Add student-specific fields
    if (userType == 'student') {
      if (enrollmentYear != null) {
        request.fields['enrollment_year'] = enrollmentYear;
      }
      if (programId != null) {
        request.fields['program_id'] = programId;
      }
    }

    // Add instructor-specific fields
    if (userType == 'instructor') {
      if (bio != null) {
        request.fields['bio'] = bio;
      }
      if (expertise != null) {
        request.fields['expertise'] = expertise;
      }
      if (qualification != null) {
        request.fields['qualification'] = qualification;
      }
    }

    // Attach profile picture if provided
    if (profilePictureFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        profilePictureFile.path,
      ));
    }

    final response = await request.send();
    final resString = await response.stream.bytesToString();
    final jsonResponse = json.decode(resString);

    if (jsonResponse['status'] == true) {
      // Update SharedPreferences for consistency
      final data = jsonResponse['data'];
      if (data != null) {
        if (data['name'] != null) {
          await prefs.setString('name', data['name']);
        }
        if (data['profile_picture_url'] != null) {
          await prefs.setString('profile_picture', data['profile_picture_url']);
        }
        // Optionally store other returned data if needed
        // Example: await prefs.setString('bio', data['bio'] ?? '');
      }
    }

    return jsonResponse;
  } catch (e) {
    return {'status': false, 'message': e.toString()};
  }
}
 Future<Map<String, dynamic>> fetchCourseDetails(String courseCatalogId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse("${BASE_URL}get_course_details.php?course_catalog_id=$courseCatalogId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception("Failed to load course details");
    }
  }

  Future<Map<String, dynamic>> submitComponent(String componentId, String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    var request = http.MultipartRequest('POST', Uri.parse("${BASE_URL}submit_component.php"));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('submission_file', filePath));
    request.fields['component_id'] = componentId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> submitFeedback({
    required String courseId,
    required String instructorId,
    required int rating,
    required String feedbackComment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse("${BASE_URL}instructor_feedback.php"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'course_id': courseId,
        'instructor_id': instructorId,
        'rating': rating,
        'feedback_comment': feedbackComment,
      }),
    );

    return json.decode(response.body);
  }
 Future<Map<String, dynamic>> getComponentSubmissionStatus(String componentId) async {
  final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';// replace with your JWT token retrieval logic

  final response = await http.get(
    Uri.parse("${BASE_URL}submissions.php?component_id=$componentId"),
    headers: {
      'Authorization': 'Bearer $token',
     
    },
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    print('Submission API Response for component $componentId: ${response.body}');

    return decoded;
  } else {
    throw Exception('Failed to fetch component submission status. Status code: ${response.statusCode}');
  }
}