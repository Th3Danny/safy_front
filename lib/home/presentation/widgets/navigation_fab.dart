import 'package:flutter/material.dart';

class NavigationFab extends StatefulWidget {
  final Function(String) onNavigationTap;

  const NavigationFab({
    super.key,
    required this.onNavigationTap,
  });

  @override
  State<NavigationFab> createState() => _NavigationFabState();
}

class _NavigationFabState extends State<NavigationFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...[
          _buildNavButton(Icons.directions_bus, 'bus'),
          const SizedBox(height: 8),
          _buildNavButton(Icons.directions_car, 'car'),
          const SizedBox(height: 8),
          _buildNavButton(Icons.directions_walk, 'walk'),
          const SizedBox(height: 8),
          _buildNavButton(Icons.add, 'add'),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: Colors.blue,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, String type) {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      onPressed: () {
        widget.onNavigationTap(type);
        _toggleExpanded();
      },
      child: Icon(
        icon,
        color: type == 'add' ? Colors.green : Colors.blue,
      ),
    );
  }
} 