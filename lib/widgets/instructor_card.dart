import 'package:flutter/material.dart';

class InstructorCard extends StatelessWidget {
  final Map<String, dynamic> instructor;

  const InstructorCard({
    super.key,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    final instructorName = instructor['instructor_name'] ?? 'Instructor';
    final expertise = instructor['expertise'] ?? 'Not specified';
    final qualification = instructor['qualification'] ?? 'Not specified';
    final bio = instructor['bio'] ?? 'No bio available';
    final imageUrl = instructor['profile_picture']; // Optional: Add profile image support.

    return InkWell(
      onTap: () {
        // For future profile navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing $instructorName\'s profile')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar
             ClipOval(
  child: Image.network(
    "https://techaccordacademy.com/tech_accord_api/$imageUrl",
    width: 64,
    height: 64,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: 64,
        height: 64,
        color: Colors.blue.shade300,
        child: const Icon(Icons.person, size: 32, color: Colors.white),
      );
    },
  ),
),

              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructorName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.work_outline, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            expertise,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 18, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            qualification,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      bio,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
