import 'package:flutter/material.dart';

class HeaderComponent extends StatelessWidget {
  final String userName;
  final VoidCallback? onSettingsTap;

  const HeaderComponent({
    Key? key,
    this.userName = 'AliHyder',
    this.onSettingsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Default Profile Icon
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.person, size: 32, color: Colors.white),
          ),
          
          // Text Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hey, $userName',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your Home',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            color: Colors.white,
            onPressed: onSettingsTap,
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.all(10),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}