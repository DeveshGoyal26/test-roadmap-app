import 'package:flutter/material.dart';
import 'package:skillpe/providers/auth_provider.dart';
import 'package:skillpe/services/api_service.dart';
import 'package:video_player/video_player.dart';
import '../widgets/video_player/video_controls.dart';
import '../widgets/video_player/video_progress_bar.dart';
import '../widgets/video_player/gradient_overlay.dart';
import '../widgets/video_player/continue_button.dart';
import '../widgets/video_player/loading_indicator.dart';
import '../widgets/video_player/error_display.dart';

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final int level;
  final String description;
  final String? videoUrl;
  final Function()? onAction;
  final String? contentId;
  final String? roadmapId;
  final String? courseId;
  const VideoPlayerPage({
    super.key,
    this.title = 'Video',
    this.level = 1,
    this.description = '',
    this.videoUrl,
    this.onAction,
    this.contentId,
    this.roadmapId,
    this.courseId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;
  bool _showContinueButton = false;
  bool _isButtonAnimating = false;
  bool _isControlsVisible = true;
  final ApiService _apiService = ApiService();
  final AuthProvider _authProvider = AuthProvider();
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          widget.videoUrl ??
              'https://masai-website-images.s3.ap-south-1.amazonaws.com/5532765_uhd_1440_2732_25fps_7c03358904.mp4',
        ),
      );
      _initializeVideoPlayerFuture = _controller.initialize().then((_) {
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
      });

      _controller.addListener(_videoListener);
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _videoListener() {
    if (_controller.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    }

    if (_controller.value.position >= _controller.value.duration) {
      setState(() {
        _showContinueButton = true;
      });
    } else if (_showContinueButton &&
        _controller.value.position < _controller.value.duration) {
      setState(() {
        _showContinueButton = false;
      });
    }
    setState(() {});
  }

  void _handlePlayPause() {
    setState(() {
      _isButtonAnimating = true;
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      Future.delayed(
        const Duration(milliseconds: 200),
        () => setState(() => _isButtonAnimating = false),
      );
    });
  }

  void _handleVideoTap() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _handleContinueButtonPressed() {
    debugPrint('Video completed, calling action callback');

    if (widget.contentId != null &&
        widget.roadmapId != null &&
        widget.courseId != null) {
      debugPrint('Content IDs are available:');
      debugPrint('ContentId: ${widget.contentId}');
      debugPrint('RoadmapId: ${widget.roadmapId}');
      debugPrint('CourseId: ${widget.courseId}');
    }

    if (widget.onAction != null) {
      debugPrint('Calling onAction callback to update progress');
      widget.onAction?.call();
    } else {
      // _apiService.updateUser(_authProvider.token as String, {
      //   'hasSeenOnboarding': true,
      // });
      Navigator.pushNamed(context, '/payment');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.only(left: 10, top: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SizedBox.expand(
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _handleVideoTap,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    VideoControls(
                      controller: _controller,
                      isPlaying: _isPlaying,
                      isButtonAnimating: _isButtonAnimating,
                      onTap: _handlePlayPause,
                    ),
                    GradientOverlay(),
                    VideoProgressBar(
                      controller: _controller,
                      showContinueButton: _showContinueButton,
                    ),
                    ContinueButton(
                      showContinueButton: _showContinueButton,
                      onPressed: _handleContinueButtonPressed,
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                return const ErrorDisplay();
              }
              return const LoadingIndicator();
            },
          ),
        ),
      ),
    );
  }
}
