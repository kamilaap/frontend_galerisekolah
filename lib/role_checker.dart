import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleChecker extends StatelessWidget {
  final Widget adminChild;
  final Widget userChild;

  const RoleChecker({
    Key? key,
    required this.adminChild,
    required this.userChild,
  }) : super(key: key);

  Future<String?> _getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getRole(),
      builder: (context, snapshot) {
        if (snapshot.data == 'admin') {
          return adminChild;
        }
        return userChild;
      },
    );
  }
}