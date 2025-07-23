import 'package:flutter/material.dart';
import 'package:techaccord/services/api_service.dart';

class RatingWidget extends StatefulWidget {
  final String instructorId;
  final String courseId;

  const RatingWidget({
    super.key,
    required this.instructorId,
    required this.courseId,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _submitted = false;
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await submitFeedback(
        courseId: widget.courseId,
        instructorId: widget.instructorId,
        rating: _rating,
        feedbackComment: _feedbackController.text.trim(),
      );

      if (response['status'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted successfully!')),
          );
          setState(() {
            _submitted = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Submission failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate Instructor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Wrap(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: _submitted || _isSubmitting
                  ? null
                  : () {
                      setState(() => _rating = index + 1);
                    },
            );
          }),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _feedbackController,
          decoration: const InputDecoration(
            labelText: 'Your feedback',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          enabled: !_submitted && !_isSubmitting,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_submitted || _isSubmitting) ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004aad),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_submitted ? 'Feedback Submitted' : 'Submit Feedback'),
          ),
        )
      ],
    );
  }
}
