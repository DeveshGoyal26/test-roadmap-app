import 'package:flutter/material.dart';
import 'package:skillpe/pages/home_page.dart';
import 'package:skillpe/pages/profile_page.dart';
import 'package:skillpe/providers/auth_provider.dart';
import 'package:ultimate_flutter_icons/flutter_icons.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;

  static final List<Widget> _pages = [
    const HomePage(),
    // const VideoPlayerPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.forward(from: 0.0);
  }

  Widget _buildAnimatedIcon(
    Widget selectedIcon,
    Widget unselectedIcon,
    bool isSelected,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = Curves.elasticOut.transform(_controller.value);
        return Transform.scale(
          scale: isSelected ? 1.0 + (0.2 * bounce) : 1.0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: isSelected ? selectedIcon : unselectedIcon,
          ),
        );
      },
    );
  }

  Widget _buildNavigationBar(BuildContext context, bool isSmallScreen) {
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final barHeight = isSmallScreen ? 64.0 : 72.0;

    // For desktop platforms, we might want to use a different navigation style
    if (UniversalPlatform.isDesktop) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, -1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          labelType: NavigationRailLabelType.all,
          backgroundColor: Theme.of(context).colorScheme.primary,
          destinations:
              _buildDestinations(
                context,
                iconSize,
              ).cast<NavigationRailDestination>(),
        ),
      );
    }

    // For mobile and tablet
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 1,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: NavigationBar(
        height: barHeight,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        indicatorColor: Theme.of(context).colorScheme.primary,
        selectedIndex: _selectedIndex,
        destinations: _buildDestinations(context, iconSize),
      ),
    );
  }

  List<Widget> _buildDestinations(BuildContext context, double iconSize) {
    final authProvider = Provider.of<AuthProvider>(context);
    return <Widget>[
      NavigationDestination(
        icon: _buildAnimatedIcon(
          FIcon(
            RI.RiHomeLine,
            size: iconSize,
            key: const ValueKey('home-filled'),
            color: Colors.black.withValues(alpha: 0.6),
          ),
          FIcon(
            RI.RiHomeLine,
            size: iconSize,
            key: const ValueKey('home-outline'),
            color: Theme.of(context).colorScheme.secondary,
          ),
          _selectedIndex == 0,
        ),
        label: 'Home',
      ),
      // NavigationDestination(
      //   icon: _buildAnimatedIcon(
      //     FIcon(
      //       BI.BiTv,
      //       size: iconSize,
      //       key: const ValueKey('tv-filled'),
      //       color: Colors.black.withValues(alpha: 0.6),
      //     ),
      //     FIcon(
      //       BI.BiTv,
      //       size: iconSize,
      //       key: const ValueKey('tv-outline'),
      //       color: Theme.of(context).colorScheme.secondary,
      //     ),
      //     _selectedIndex == 1,
      //   ),
      //   label: 'Library',
      // ),
      NavigationDestination(
        icon: Builder(
          builder: (context) {
            final user = authProvider.userInfo;
            if (user?.profileImage != null) {
              return _buildAnimatedIcon(
                CircleAvatar(
                  radius: iconSize / 2,
                  backgroundColor: Colors.grey[200],
                  key: const ValueKey('user-profile-filled'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(iconSize),
                    child: Image.network(
                      user?.profileImage ?? user?.avatarUrl ?? '',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: iconSize / 2,
                  backgroundColor: Colors.grey[200],
                  key: const ValueKey('user-profile-outline'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(iconSize),
                    child: Image.network(
                      user?.profileImage ?? user?.avatarUrl ?? '',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    ),
                  ),
                ),
                _selectedIndex == 2,
              );
            } else {
              // Fallback to the original icon if no profile image
              return _buildAnimatedIcon(
                FIcon(
                  RI.RiHomeLine,
                  size: iconSize,
                  key: const ValueKey('user-filled'),
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                FIcon(
                  RI.RiUserLine,
                  size: iconSize,
                  key: const ValueKey('user-outline'),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _selectedIndex == 2,
              );
            }
          },
        ),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      body: Row(children: [Expanded(child: _pages[_selectedIndex])]),
      bottomNavigationBar:
          UniversalPlatform.isDesktop
              ? null
              : _buildNavigationBar(context, isSmallScreen),
    );
  }
}
