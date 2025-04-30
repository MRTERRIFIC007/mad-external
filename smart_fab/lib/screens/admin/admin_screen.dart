import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_fab/core/core.dart';
import 'package:smart_fab/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_fab/screens/admin/reports_screen.dart';
import 'package:smart_fab/screens/scanner/scanner_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedIndex = 0;
  
  // Safe accessor for pages to prevent out-of-bounds errors
  Widget _getPage(int index) {
    final List<Widget> pages = [
      // Wrap each screen in error boundaries to prevent cascading failures
      ErrorBoundary(child: const AdminDashboardScreen()),
      ErrorBoundary(child: const ScannerScreen()),
      ErrorBoundary(child: const ReportsScreen()),
    ];
    
    if (index < 0 || index >= pages.length) {
      // Return a fallback page if index is out of bounds
      return const Center(child: Text('Page not found'));
    }
    
    return pages[index];
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Simple error boundary to prevent cascade failures
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  
  const ErrorBoundary({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return child;
  }
} 