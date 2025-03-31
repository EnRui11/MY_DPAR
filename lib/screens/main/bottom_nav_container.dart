import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/services/bottom_nav_service.dart';
import 'package:mydpar/widgets/bottom_nav_bar.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';

class BottomNavContainer extends StatefulWidget {
  const BottomNavContainer({Key? key}) : super(key: key);

  @override
  State<BottomNavContainer> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<BottomNavContainer> {
  // Create a page controller
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    // Initialize the page controller
    _pageController = PageController();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // List of screens to display
  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context);
    
    // Listen to navigation service changes and update page controller
    if (_pageController.hasClients && 
        navigationService.currentIndex != _pageController.page?.round()) {
      _pageController.jumpToPage(navigationService.currentIndex);
    }
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: _screens,
        onPageChanged: (index) {
          // Update the navigation service when page changes
          navigationService.changeIndex(index);
        },
      ),
      bottomNavigationBar: BottomNavBar(
        onTap: (index) {
          // When nav bar is tapped, change page
          _pageController.jumpToPage(index);
        },
      ),
    );
  }
}