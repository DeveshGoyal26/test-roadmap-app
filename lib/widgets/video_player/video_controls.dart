import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isPlaying;
  final bool isButtonAnimating;
  final Function() onTap;
  final Duration animationDuration;

  const VideoControls({
    super.key,
    required this.controller,
    required this.isPlaying,
    required this.isButtonAnimating,
    required this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaying == false || isButtonAnimating) {
      return Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(
            begin: isPlaying ? 1.0 : 0.0,
            end: isPlaying ? 0.0 : 1.0,
          ),
          duration: animationDuration,
          builder: (context, double value, child) {
            return AnimatedOpacity(
              opacity: value,
              duration: animationDuration,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: animationDuration,
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      key: ValueKey<bool>(isPlaying),
                      color: Colors.black,
                      size: 55,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}