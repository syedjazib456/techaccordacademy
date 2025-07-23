import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:techaccord/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ComponentCard extends StatefulWidget {
  final Map<String, dynamic> component;
  final String courseId;
  final VoidCallback onRefresh;

  const ComponentCard({
    super.key,
    required this.component,
    required this.courseId,
    required this.onRefresh,
  });

  @override
  State<ComponentCard> createState() => _ComponentCardState();
}

class _ComponentCardState extends State<ComponentCard> {
  bool _isSubmitting = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  String? _submissionStatus;

  @override
  void initState() {
    super.initState();
    _loadSubmissionStatus();
  }

  @override
  void didUpdateWidget(ComponentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.component['id'] != oldWidget.component['id']) {
      _loadSubmissionStatus();
    }
  }

  Future<void> _loadSubmissionStatus() async {
    try {
      final response = await getComponentSubmissionStatus(widget.component['id'].toString());
      if (response['status'] == true) {
        final submissions = response['submissions'] as List<dynamic>;
        if (submissions.isNotEmpty) {
          final submission = submissions.first;
          setState(() {
            _submissionStatus = submission['status']?.toString();
          });
        } else {
          setState(() => _submissionStatus = null);
        }
      } else {
        setState(() => _submissionStatus = null);
      }
    } catch (e) {
      setState(() => _submissionStatus = null);
    }
  }

  void _showSnackbar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: backgroundColor ?? Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickFile() async {
    if (_submissionStatus == 'submitted' || _submissionStatus == 'marked') {
      _showSnackbar('Submission already made. Cannot select another file.', backgroundColor: Colors.orange);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      final tempPath = result.files.single.path!;
      final fileName = result.files.single.name;

      try {
        final appDir = await getApplicationDocumentsDirectory();
        final savedFile = await File(tempPath).copy('${appDir.path}/$fileName');

        setState(() {
          _selectedFilePath = savedFile.path;
          _selectedFileName = fileName;
        });

        _showSnackbar('Selected file: $fileName', backgroundColor: Colors.green);
      } catch (e) {
        _showSnackbar('File copy failed: $e', backgroundColor: Colors.red);
      }
    } else {
      _showSnackbar('No file selected', backgroundColor: Colors.orange);
    }
  }

  Future<void> _handleSubmit() async {
    if (_submissionStatus == 'submitted' || _submissionStatus == 'marked') {
      _showSnackbar('You have already submitted this assignment.', backgroundColor: Colors.orange);
      return;
    }

    if (_selectedFilePath == null) {
      _showSnackbar('Please choose a file first.', backgroundColor: Colors.orange);
      return;
    }

    if (!File(_selectedFilePath!).existsSync()) {
      _showSnackbar('File no longer exists, please reselect.', backgroundColor: Colors.red);
      setState(() {
        _selectedFilePath = null;
        _selectedFileName = null;
      });
      return;
    }

    final componentId = widget.component['id'].toString();
    setState(() => _isSubmitting = true);
    _showSnackbar('Uploading your submission...', backgroundColor: Colors.blue);

    try {
      final response = await submitComponent(componentId, _selectedFilePath!);

      if (response['status'] == true) {
        if (!mounted) return;
        _showSnackbar('Submission uploaded successfully!', backgroundColor: Colors.green);
        setState(() {
          _selectedFilePath = null;
          _selectedFileName = null;
        });
        await _loadSubmissionStatus();
        widget.onRefresh();
      } else {
        _showSnackbar(response['message'] ?? 'Upload failed', backgroundColor: Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    String text;
    switch (status) {
      case 'submitted':
        bgColor = Colors.orange.shade600;
        text = 'Submitted';
        break;
      case 'marked':
        bgColor = Colors.green.shade700;
        text = 'Marked';
        break;
      case 'returned':
        bgColor = Colors.blue.shade600;
        text = 'Returned';
        break;
      default:
        bgColor = Colors.grey.shade600;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = _isSubmitting ||
        _submissionStatus == 'submitted' ||
        _submissionStatus == 'marked';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.component['title'] ?? 'Component',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Text('Type: ${widget.component['component_type'] ?? '-'}',
                style: const TextStyle(color: Colors.black87, fontSize: 14)),
            Text('Due: ${widget.component['due_date'] ?? '-'}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            if (_submissionStatus != null)
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 13)),
                  _buildStatusBadge(_submissionStatus!),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: isDisabled ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled ? Colors.grey : Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFileName ?? 'No file selected',
                    style: TextStyle(
                      fontStyle: _selectedFileName == null ? FontStyle.italic : FontStyle.normal,
                      color: _selectedFileName == null ? Colors.grey : Colors.black87,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isDisabled ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : (_submissionStatus == 'marked'
                          ? 'Marked'
                          : (_submissionStatus == 'submitted' ? 'Submitted' : 'Submit')),
                  style: const TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDisabled ? Colors.grey : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
