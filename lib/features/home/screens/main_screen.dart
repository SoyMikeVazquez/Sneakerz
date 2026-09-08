import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sneakerz_app/core/constants/colors.dart';
import 'package:sneakerz_app/features/booking/screens/branch_selection_screen.dart';
import 'package:sneakerz_app/features/map/screens/map_screen.dart';
import 'package:sneakerz_app/features/orders/screens/order_status_screen.dart';
import 'package:sneakerz_app/features/auth/screens/login_screen.dart';
import 'package:sneakerz_app/features/auth/providers/auth_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }


  final List<Widget> _screens = const [
    BranchSelectionScreen(),
    MapScreen(),
    OrderStatusScreen(),
    LoginScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: _buildLiquidGlassBottomNav(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidGlassBottomNav() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40, bottom: 24), // Adjusted padding for 4 items
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 64, // Smaller height
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // True frosted glass
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1), // Subtle light border, no black
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 0),
                _buildNavItem(Icons.map_outlined, Icons.map, 1),
                _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 2),
                _buildNavItem(Icons.person_outline, Icons.person, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData unselected, IconData selected, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        // Si intenta ir a la pestaña de Pedidos (índice 2)
        if (index == 2) {
          final isStaff = ref.read(currentUserProvider) != null;
          final isCustomer = ref.read(customerSessionProvider) != null;
          
          if (!isStaff && !isCustomer) {
            // No está logueado, ir a la pantalla de login directamente en el menú
            setState(() => _currentIndex = 3);
            return;
          }
        }
        
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          isSelected ? selected : unselected,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}
