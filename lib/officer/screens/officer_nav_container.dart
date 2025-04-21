import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mydpar/officer/services/officer_nav_service.dart';
import 'package:mydpar/officer/widgets/officer_nav_bar.dart';

class OfficerNavContainer extends StatefulWidget {
  const OfficerNavContainer({Key? key}) : super(key: key);

  @override
  State<OfficerNavContainer> createState() => _OfficerNavContainerState();
}

class _OfficerNavContainerState extends State<OfficerNavContainer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OfficerNavigationService>(context, listen: false)
          .changeIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = Provider.of<OfficerNavigationService>(context);
    final currentIndex = navigationService.currentIndex;

    return Scaffold(
      body: navigationService.getScreenForIndex(currentIndex),
      bottomNavigationBar: OfficerNavBar(
        onTap: (index) {
          navigationService.changeIndex(index);
        },
      ),
    );
  }
}
