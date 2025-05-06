import 'package:flutter/material.dart';
import 'package:skillpe/services/category_service.dart';
import 'package:skillpe/widgets/cards/course_card.dart';
import 'package:skillpe/widgets/custom_snackbar.dart';
import 'package:logger/logger.dart';
import 'package:universal_platform/universal_platform.dart';

class CategoryPage extends StatelessWidget {
  final String id;
  final String? title;
  const CategoryPage({super.key, required this.id, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: AppBar(
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'Category',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                Text(title ?? 'Category'),
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
        ),
      ),
      body: CategoryItem(id: id, title: title ?? '', icon: ''),
    );
  }
}

class CategoryItem extends StatefulWidget {
  final String title;
  final String icon;
  final String id;

  const CategoryItem({
    super.key,
    required this.id,
    required this.title,
    required this.icon,
  });

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  final logger = Logger();
  final categoryService = CategoryService();
  List<dynamic> courses = [];
  bool isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;

    try {
      final response = await categoryService.getCategoryById(widget.id);

      if (!_mounted) return;

      setState(() {
        courses = response['courses'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      logger.e(e);

      if (!_mounted) return;

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Failed to load categories. Please try again.',
        );
      }
    }
  }

  Widget _buildCoursesGrid() {
    final isWeb = UniversalPlatform.isWeb;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No courses available yet',
                style:
                    isWeb
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for new courses in this category',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: courses.length,
          itemBuilder:
              (context, index) =>
                  CourseCard(course: courses[index], isWeb: isWeb),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchCategories,
      child: _buildCoursesGrid(),
    );
  }
}
