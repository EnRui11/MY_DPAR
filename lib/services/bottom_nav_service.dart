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
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Get screen name based on index
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
        return 'Unknown';
    }
  }

  // Get icon data based on index
  IconData getScreenIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.map_outlined;
      case 2:
        return Icons.people_outline;
      case 3:
        return Icons.person_outline;
      default:
        return Icons.error;
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

      // Create the appropriate screen based on index
      Widget screen;
      switch (index) {
        case 0:
          screen = const HomeScreen();
          break;
        case 1:
          screen = const MapScreen();
          break;
        case 2:
          screen = const CommunityScreen();
          break;
        case 3:
          screen = const ProfileScreen();
          break;
        default:
          return;
      }

      // Navigate using MaterialPageRoute instead of named routes
      if (replace) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => screen));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      }
    }
  }
}
