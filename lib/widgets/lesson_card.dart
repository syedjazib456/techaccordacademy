import 'package:flutter/material.dart';

class LessonCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline, color: Colors.blue),
        title: Text(lesson['title']),
        subtitle: Text('Type: ${lesson['lesson_type']}'),
        onTap: onTap,
      ),
    );
  }
}
