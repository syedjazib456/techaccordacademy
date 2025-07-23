
// view_course_screen.dart for Tech Accord Flutter App (Updated)

import 'package:flutter/material.dart';
import 'package:techaccord/services/api_service.dart';
import 'package:techaccord/widgets/course_video_player.dart';
import 'package:techaccord/widgets/lesson_card.dart';
import 'package:techaccord/widgets/component_card.dart';
import 'package:techaccord/widgets/instructor_card.dart';
import 'package:techaccord/widgets/ratings_widget.dart';

class ViewCourseScreen extends StatefulWidget {
  final String courseCatalogId;

  const ViewCourseScreen({super.key, required this.courseCatalogId});

  @override
  State<ViewCourseScreen> createState() => _ViewCourseScreenState();
}

class _ViewCourseScreenState extends State<ViewCourseScreen> {
  Map<String, dynamic>? course;
  List<dynamic> lessons = [];
  List<dynamic> components = [];
  bool loading = true;
  Map<String, dynamic>? selectedLesson;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      loading = true;
    });

    final data = await fetchCourseDetails(widget.courseCatalogId);
    if (!mounted) return;

    if (data != null && data['status'] == true) {
      setState(() {
        course = data['course'];
        lessons = data['lessons'] ?? [];
        components = data['components'] ?? [];
        selectedLesson = lessons.isNotEmpty ? lessons[0] : null;
        loading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load course details')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _selectLesson(Map<String, dynamic> lesson) {
    setState(() {
      selectedLesson = lesson;
    });
  }

  String _getFullImageUrl(String? thumbnailPath) {
    if (thumbnailPath == null || thumbnailPath.isEmpty) {
      return 'https://via.placeholder.com/150'; // fallback
    }
    if (thumbnailPath.startsWith('http')) {
      return thumbnailPath;
    }
    return 'https://techaccordacademy.com/tech_accord_api/api/$thumbnailPath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Course', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF004aad),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourseDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: course == null
                    ? const Center(child: Text("Course details not found."))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _getFullImageUrl(course!['thumbnail']),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 60),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course!['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(course!['description'] ?? 'No description available.'),
                                    const SizedBox(height: 8),
                                    Text('Price: Rs. ${course!['price'] ?? '0'}'),
                                    Text('Duration: ${course!['course_duration'] ?? '-'}'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Video Section
                          const Text(
                            'Watch Lesson',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (selectedLesson != null)
                            CourseVideoPlayer(lesson: selectedLesson!)
                          else
                            const Text(
                              'No lesson video available.',
                              style: TextStyle(color: Colors.grey),
                            ),

                          const SizedBox(height: 20),

                          // Lessons List
                          const Text(
                            'All Lessons',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (lessons.isNotEmpty)
                            ...lessons.map(
                              (lesson) => LessonCard(
                                lesson: lesson,
                                onTap: () => _selectLesson(lesson),
                              ),
                            )
                          else
                            const Text('No lessons available.'),

                          const SizedBox(height: 20),

                          // Components List
                          const Text(
                            'Course Evaluation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (components.isNotEmpty)
                            ...components.map(
                              (component) => ComponentCard(
                                component: component,
                                courseId: widget.courseCatalogId,
                                onRefresh: _loadCourseDetails,
                              ),
                            )
                          else
                            const Text('No evaluation components available.'),

                          const SizedBox(height: 20),

                          // Instructor Details
                          const Text(
                            'Instructor',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          InstructorCard(instructor: course!),

                          const SizedBox(height: 20),

                          // Feedback Section
                          const Text(
                            'Leave Feedback',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          RatingWidget(
                            instructorId: course!['instructor_id'].toString(),
                            courseId: widget.courseCatalogId,
                          ),
                        ],
                      ),
              ),
            ),
    );
  }
}
