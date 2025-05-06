import 'package:flutter/material.dart';

class HeaderComponent extends StatelessWidget {
  final String subtitle;
  final String title;
  final VoidCallback? onBackPressed;
  final Color subtitleColor;
  final Color titleColor;
  final bool isLoading;

  const HeaderComponent({
    super.key,
    this.subtitle = 'Design',
    this.title = 'Product Design',
    this.onBackPressed,
    this.subtitleColor = const Color(0xFF9933FF),
    this.titleColor = const Color(0xFF000000),
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isLoading)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 2),
        if (!isLoading)
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
