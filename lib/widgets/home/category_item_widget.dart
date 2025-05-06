import 'package:flutter/material.dart';
import 'package:skillpe/pages/category_page.dart';
import 'package:universal_platform/universal_platform.dart';
import 'category_item.dart' as category_item;

class CategoryItemWidget extends StatelessWidget {
  final category_item.CategoryItem category;

  const CategoryItemWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    // Calculate dynamic sizes based on screen width
    final iconSize = screenSize.width * (UniversalPlatform.isWeb ? 0.03 : 0.12);
    // Constrain the size to reasonable min/max values
    final constrainedIconSize = iconSize.clamp(35.0, 60.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: () => _navigateToCategory(context),
          child: Container(
            width: 55,
            height: 55,
            constraints: BoxConstraints(
              minWidth: 55,
              maxWidth: 55,
              minHeight: 55,
              maxHeight: 55,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 3,
                  child: Container(
                    width: constrainedIconSize,
                    height: constrainedIconSize,
                    margin: EdgeInsets.symmetric(
                      vertical: constrainedIconSize * 0.1,
                    ),
                    child: IconButton(
                      onPressed: () => _navigateToCategory(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                      ),
                      icon: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipOval(
                            child: Image.network(
                              category.imagePath,
                              width: constrainedIconSize * 0.6,
                              height: constrainedIconSize * 0.6,
                              fit: BoxFit.contain,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.fallback,
                            ),
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigateToCategory(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constrainedIconSize * 0.1,
                      vertical: constrainedIconSize * 0.05,
                    ),
                    child: Text(
                      category.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: (constrainedIconSize * 0.24).clamp(
                          10.0,
                          14.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToCategory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CategoryPage(id: category.id, title: category.title),
      ),
    );
  }
}
