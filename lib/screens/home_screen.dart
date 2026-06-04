import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'client_map_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isAdmin = false;

    if (kIsWeb) {
      isAdmin = true; // For web we can assume admin or check
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      isAdmin = true;
    }

    if (isAdmin) {
      return const AdminDashboardScreen();
    } else {
      return const ClientMapScreen();
    }
  }
}
