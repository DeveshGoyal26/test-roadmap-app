import 'package:flutter/material.dart';
import 'package:skillpe/services/category_service.dart';
import 'package:skillpe/widgets/home/category_item.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/home/app_logo.dart';
import '../../widgets/home/theme_toggle_button.dart';
import '../../widgets/home/category_grid.dart';
import '../../widgets/home/main_content.dart';
import '../../widgets/home/category_skeleton.dart';
import '../../widgets/custom_snackbar.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final categoryService = CategoryService();
  List<CategoryItem> categories = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Add a slightly longer delay for categories to ensure token is ready
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchCategories();
      }
    });
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;

    try {
      // Add retry mechanism with exponential backoff
      int retryCount = 0;
      const maxRetries = 1;

      while (retryCount < maxRetries) {
        try {
          final response = await categoryService.getCategories();

          if (!mounted) return;

          setState(() {
            categories =
                response
                    .map(
                      (category) => CategoryItem(
                        id: category['_id'].toString(),
                        title: category['title'],
                        imagePath: category['icon'] ?? 'assets/icons/like.png',
                      ),
                    )
                    .toList();
            isLoading = false;
            isRefreshing = false;
          });

          // If successful, break the retry loop
          break;
        } catch (e) {
          debugPrint('Attempt ${retryCount + 1} failed: $e');
          retryCount++;

          if (retryCount >= maxRetries) {
            throw e; // Throw the error if max retries reached
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
      });

      if (mounted) {
        CustomSnackBar.showError(
          context: context,
          message: 'Failed to load categories. Please try again.',
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      isRefreshing = true;
    });

    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isMediumScreen = screenSize.width >= 600 && screenSize.width < 1200;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(themeProvider, isSmallScreen),
      body: RefreshIndicator(
        backgroundColor: Theme.of(context).colorScheme.surface,
        onRefresh: _onRefresh,
        child: _buildBody(themeProvider, isSmallScreen, isMediumScreen),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeProvider themeProvider,
    bool isSmallScreen,
  ) {
    return AppBar(
      centerTitle: true,
      toolbarHeight: isSmallScreen ? kToolbarHeight : 70,
      forceMaterialTransparency: true,
      elevation: 0,
      title: Padding(
        padding: EdgeInsets.only(left: isSmallScreen ? 0 : 16),
        child: AppLogo(themeProvider: themeProvider),
      ),
      actions: [
        ThemeToggleButton(themeProvider: themeProvider),
        SizedBox(width: isSmallScreen ? 8 : 16),
      ],
    );
  }

  Widget _buildBody(
    ThemeProvider themeProvider,
    bool isSmallScreen,
    bool isMediumScreen,
  ) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            themeProvider.isDarkMode
                ? 'assets/images/home-bg.png'
                : 'assets/images/home-bg.png',
          ),
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            isLoading
                ? _buildSkeletonGrid(isSmallScreen, isMediumScreen)
                : CategoryGrid(categories: categories),
            _buildDivider(),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 0 : 24,
                ),
                child: const MainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid(bool isSmallScreen, bool isMediumScreen) {
    final screenWidth = min(MediaQuery.of(context).size.width, 450.0);
    final isWeb = UniversalPlatform.isWeb;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isWeb ? 1200 : double.infinity, // Limit max width on web
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 15 : 10,
          vertical: isWeb ? 16 : 10,
        ),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(screenWidth),
          crossAxisSpacing: isWeb ? 24 : 16,
          mainAxisSpacing: isWeb ? 24 : 10,
          childAspectRatio: _getChildAspectRatio(screenWidth),
        ),
        itemCount:
            isSmallScreen
                ? 6
                : UniversalPlatform.isWeb
                ? 6
                : isMediumScreen
                ? 8
                : 12,
        itemBuilder: (context, index) => const CategorySkeleton(),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Theme.of(context).colorScheme.outline,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 3; // Mobile
    if (width < 1200) return 4; // Tablet
    if (width < 1800) return 6; // Desktop
    return 8; // Large Desktop
  }

  double _getChildAspectRatio(double width) {
    if (width < 600) return 1.18; // Mobile
    if (width < 1200) return 1.3; // Tablet
    return 2; // Desktop and larger
  }
}
