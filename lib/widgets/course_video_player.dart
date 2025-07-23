// Final, stable, clean Tech Accord CourseVideoPlayer.dart
// Handles YouTube, Drive, direct video, and live session cleanly with WebView Flutter stability.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseVideoPlayer extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const CourseVideoPlayer({super.key, required this.lesson});

  @override
  State<CourseVideoPlayer> createState() => _CourseVideoPlayerState();
}

class _CourseVideoPlayerState extends State<CourseVideoPlayer> with WidgetsBindingObserver {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  WebViewController? _webViewController;

  bool _loading = true;
  bool _isYouTube = false;
  bool _isDrive = false;
  bool _isLive = false;
  bool _isPageLoading = true;
  bool _webViewError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _youtubeController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _webViewController?.runJavaScript('document.body.innerHTML = "";');
    }
  }

  Future<void> _initializePlayer() async {
    final url = (widget.lesson['video_url'] ?? '').trim();
    debugPrint("Initializing video for URL: $url");

    if (url.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (url.contains('zoom') || url.contains('meet') || url.contains('live')) {
      _isLive = true;
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final videoId = YoutubePlayer.convertUrlToId(url);
      debugPrint("Parsed YouTube video ID: $videoId");
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false),
        );
        _isYouTube = true;
      }
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (url.contains('drive.google.com')) {
      final fileId = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1);
      final embedUrl = fileId != null
          ? "https://drive.google.com/file/d/$fileId/preview"
          : url;

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() {
                _isPageLoading = true;
                _webViewError = false;
              });
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isPageLoading = false);
            },
            onWebResourceError: (error) {
              debugPrint("WebView error: $error");
              if (mounted) setState(() {
                _webViewError = true;
                _isPageLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(embedUrl));

      _isDrive = true;
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();
    } catch (e) {
      debugPrint("Video initialization failed: $e");
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isLive) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.video_call),
          label: const Text("Join Live Session"),
          onPressed: () async {
            final url = widget.lesson['video_url'];
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not launch live session link')),
                );
              }
            }
          },
        ),
      );
    }

    if (_isYouTube && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
      );
    }

  if (_isDrive) {
  return Center(
    child: ElevatedButton.icon(
      icon: const Icon(Icons.open_in_browser),
      label: const Text("Open Lecture Video"),
      onPressed: () async {
        final url = widget.lesson['video_url'];
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the video link.')),
          );
        }
      },
    ),
  );
}



    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_videoController!),
            VideoProgressIndicator(_videoController!, allowScrubbing: true),
            Align(
              alignment: Alignment.bottomCenter,
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                mini: true,
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text("Unable to load video for this lesson."));
  }
}
