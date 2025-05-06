import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  final bool showContinueButton;
  final Duration animationDuration;

  const VideoProgressBar({
    super.key,
    required this.controller,
    required this.showContinueButton,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: animationDuration,
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      bottom: showContinueButton ? 80 : 10,
      child: SliderTheme(
        data: SliderThemeData(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
          activeTrackColor: Colors.white.withValues(alpha: 0.8),
          inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          trackHeight: 3,
          thumbColor: Colors.white,
          overlayColor: Colors.white.withValues(alpha: 0.12),
        ),
        child: Slider(
          value: controller.value.position.inMilliseconds.toDouble(),
          min: 0,
          max: controller.value.duration.inMilliseconds.toDouble(),
          onChanged: (value) {
            controller.seekTo(Duration(milliseconds: value.toInt()));
          },
        ),
      ),
    );
  }
}