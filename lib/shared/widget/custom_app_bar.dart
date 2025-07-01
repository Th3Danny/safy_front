import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safy/core/router/domain/constants/app_routes_constant.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(
                      AppRoutesConstant.home,
                    ); // o donde quieras redirigir
                  }
                },
              )
              : null,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[200]),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
