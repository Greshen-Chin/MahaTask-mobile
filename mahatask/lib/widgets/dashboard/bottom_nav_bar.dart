import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.messagesUnread = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int messagesUnread;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
    _NavItem(icon: Icons.assignment_turned_in_outlined, label: 'Tasks'),
    _NavItem(icon: Icons.calendar_month_outlined, label: 'Scheduler'),
    _NavItem(icon: Icons.chat_bubble_outline, label: 'Messages'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? const Color(0xFF171717) : Colors.white;
    final activeBg = isDark ? Colors.cyanAccent.withOpacity(0.12) : Theme.of(context).colorScheme.primary.withOpacity(0.12);
    final activeIcon = Theme.of(context).colorScheme.primary;
    final inactiveIcon = isDark ? Colors.white54 : Colors.black45;
    final activeText = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveText = isDark ? Colors.white38 : Colors.black45;
    final shadow = isDark ? const Color(0x40000000) : const Color(0x14000000);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadow,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isActive = currentIndex == index;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        scale: isActive ? 1.07 : 1,
                        child: Icon(
                          item.icon,
                          color: isActive ? activeIcon : inactiveIcon,
                          size: 23,
                        ),
                      ),
                      if (index == 3 && messagesUnread > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            messagesUnread > 99 ? '99+' : '$messagesUnread',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? activeText : inactiveText,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
