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
  static final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationService>(context, listen: false).changeIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<NavigationService>(context);
    final currentIndex = navigationService.currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        onTap: (index) {
          navigationService.changeIndex(index);
        },
      ),
    );
  }
}
