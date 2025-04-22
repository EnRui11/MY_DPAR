import 'package:flutter/material.dart';
import 'package:mydpar/screens/main/home_screen.dart';
import 'package:mydpar/screens/main/map_screen.dart';
import 'package:mydpar/screens/main/community_screen.dart';
import 'package:mydpar/screens/main/profile_screen.dart';

class NavigationService extends ChangeNotifier {
  // Current selected index for bottom navigation
  int _currentIndex = 0;

  // Getter for current index
  int get currentIndex => _currentIndex;

  // List of main screen routes
  static const List<String> routes = [
    '/home',
    '/map',
    '/community',
    '/profile',
  ];

  // Method to change the current index
  void changeIndex(int index) {
    if (index >= 0 && index < routes.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Navigate to a specific screen using route name
  void navigateToNamed(BuildContext context, String routeName,
      {bool replace = false}) {
    if (replace) {
      Navigator.pushReplacementNamed(context, routeName);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  // Navigate to a specific screen using index
  void navigateToIndex(BuildContext context, int index,
      {bool replace = false}) {
    if (index >= 0 && index < routes.length) {
      changeIndex(index);
      if (replace) {
        Navigator.pushReplacementNamed(context, routes[index]);
      } else {
        Navigator.pushNamed(context, routes[index]);
      }
    }
  }

  // Get the route name for a specific index
  String getRouteForIndex(int index) {
    if (index >= 0 && index < routes.length) {
      return routes[index];
    }
    return routes[0]; // Default to home
  }

  // Get the widget for a specific index
  Widget getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const CommunityScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  // Get the name for a specific screen index
  String getScreenName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Map';
      case 2:
        return 'Community';
      case 3:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  // Get the icon for a specific screen index
  IconData getScreenIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.map;
      case 2:
        return Icons.people;
      case 3:
        return Icons.person;
      default:
        return Icons.home;
    }
  }
}
