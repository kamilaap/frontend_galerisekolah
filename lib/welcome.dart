import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'home.dart';
import 'info.dart';
import 'agenda.dart';
import 'galery.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    InformasiScreen(),
    AgendaScreen(),
    GaleryScreen(),
  ];

  Timer? _timer;
  String _timeString = '';
  String _dateString = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _getTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = _formatDateTime(now);
      _dateString = _formatDate(now);
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.Hms('id_ID').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat.yMMMMEEEEd('id_ID').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _timeString,
              style: TextStyle(
                color: const Color(0xFFF7EEDD),
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 28 : 24,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _dateString,
              style: TextStyle(
                color: const Color(0xFFF7EEDD),
                fontSize: isTablet ? 18 : 16,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF008DDA),
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.home_outlined, 'Home', 0),
                activeIcon: _buildActiveIcon(Icons.home, 'Home', 0),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.info_outline, 'Info', 1),
                activeIcon: _buildActiveIcon(Icons.info, 'Info', 1),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.calendar_today_outlined, 'Agenda', 2),
                activeIcon: _buildActiveIcon(Icons.calendar_today, 'Agenda', 2),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.photo_library_outlined, 'Galeri', 3),
                activeIcon: _buildActiveIcon(Icons.photo_library, 'Galeri', 3),
                label: '',
              ),
            ],
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF008DDA),
            unselectedItemColor: Colors.grey[400],
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, String label, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIcon(IconData icon, String label, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF008DDA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008DDA),
            ),
          ),
        ],
      ),
    );
  }
}
