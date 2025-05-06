import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContinueButton extends StatelessWidget {
  final bool showContinueButton;
  final Duration animationDuration;
  final VoidCallback onPressed;

  const ContinueButton({
    super.key,
    required this.showContinueButton,
    required this.onPressed,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: animationDuration,
      curve: Curves.easeInOut,
      bottom: showContinueButton ? 10 : -100,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AnimatedOpacity(
          opacity: showContinueButton ? 1.0 : 0.0,
          duration: animationDuration,
          curve: Curves.easeInOut,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onPressed();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}