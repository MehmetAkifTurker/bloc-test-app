import 'package:bloc_test_app/ui/screens/box_check_scan_screen/box_check_scan_screen.dart';
import 'package:bloc_test_app/ui/screens/main_menu/main_menu.dart';
import 'package:bloc_test_app/ui/screens/rfid_db_tag_list_screen/rfid_tag_list_screen.dart';
import 'package:bloc_test_app/ui/screens/rfid_scan_tag_list_screen/rfid_scan_tag_list_screen.dart';
import 'package:flutter/material.dart';

import '../screens/tag_write_screen/tag_write_screen.dart';

class AppRouter {
  Route onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainMenu());
      case '/db':
        return MaterialPageRoute(builder: (_) => const RfidTagListScreen());

      case '/rfidscan':
        return MaterialPageRoute(builder: (_) => RfidScanTagListScreen());
      case '/boxcheck':
        return MaterialPageRoute(builder: (_) => BoxCheckListScreen());
      case '/tagwrite':
        return MaterialPageRoute(builder: (_) => const TagWriteScreen());

      default:
        return MaterialPageRoute(builder: (_) => const RfidTagListScreen());
    }
  }
}

List<String> pageNames = [
  '/',
  '/boxcheck',
  '/rfidscan',
  '/db',
  '/tagwrite',
];
