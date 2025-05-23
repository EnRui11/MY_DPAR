import 'package:flutter/material.dart';
import 'package:mydpar/officer/screens/main/community_groups_screen.dart';
import 'package:mydpar/officer/screens/main/emergency_teams_screen.dart';
import 'package:mydpar/officer/screens/main/officer_dashboard_screen.dart';
import 'package:mydpar/officer/screens/main/shelter_management_screen.dart';

class OfficerNavigationService extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  static const List<String> routes = [
    '/officer/dashboard',
    '/officer/shelter',
    '/officer/teams',
    '/officer/community',
  ];

  void changeIndex(int index) {
    if (index >= 0 && index < routes.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  String getRouteForIndex(int index) {
    if (index >= 0 && index < routes.length) {
      return routes[index];
    }
    return routes[0];
  }

  Widget getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const OfficerDashboardScreen();
      case 1:
        return const ShelterManagementScreen();
      case 2:
        return const EmergencyTeamsScreen();
      case 3:
        return const CommunityGroupsScreen();
      default:
        return const OfficerDashboardScreen();
    }
  }

  String getScreenName(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Shelter & Resource';
      case 2:
        return 'Emergency Teams';
      case 3:
        return 'Community';
      default:
        return 'Dashboard';
    }
  }

  IconData getScreenIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.home;
      case 2:
        return Icons.people;
      case 3:
        return Icons.groups;
      default:
        return Icons.dashboard;
    }
  }
}
