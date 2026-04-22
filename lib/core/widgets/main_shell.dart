import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vrs_transport_manager/core/theme/app_colors.dart';
import 'package:vrs_transport_manager/core/theme/app_text_styles.dart';
import 'package:vrs_transport_manager/core/widgets/confirmation_dialog.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vrs_transport_manager/features/auth/presentation/bloc/auth_event.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(),
          Container(width: 0.5, color: AppColors.separator),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 200,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo + company name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child:
                      Image.asset('assets/logo_512.png', width: 32, height: 32),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VRS Enterprises',
                        style: AppTextStyles.subtitle
                            .copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Transport Manager',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MODULES',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Nav items
          _NavItem(
            icon: Icons.local_shipping_outlined,
            activeIcon: Icons.local_shipping,
            label: 'Transport',
            isActive: location == '/' ||
                location.startsWith('/create') ||
                location.startsWith('/edit') ||
                location.startsWith('/detail'),
            onTap: () => context.go('/'),
          ),
          _NavItem(
            icon: Icons.construction_outlined,
            activeIcon: Icons.construction,
            label: 'Machinery',
            isActive: location.startsWith('/machinery'),
            onTap: () => context.go('/machinery'),
          ),
          _NavItem(
            icon: Icons.summarize_outlined,
            activeIcon: Icons.summarize,
            label: 'Reports',
            isActive: location.startsWith('/reports'),
            onTap: () => context.go('/reports'),
          ),
          _NavItem(
            icon: Icons.payments_outlined,
            activeIcon: Icons.payments,
            label: 'Payments',
            isActive: location.startsWith('/payments'),
            onTap: () => context.go('/payments'),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            label: 'Invoices',
            isActive: location.startsWith('/invoices'),
            onTap: () => context.go('/invoices'),
          ),

          const Spacer(),

          // Settings
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              isActive: location.startsWith('/settings'),
              onTap: () => context.go('/settings'),
            ),
          ),

          const Divider(
            height: 0.5,
            indent: 16,
            endIndent: 16,
            color: AppColors.separator,
          ),
          const SizedBox(height: 8),

          // Dev credit
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Developed by Asfar',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 8),

          // Sign Out
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _NavItem(
              icon: Icons.logout_rounded,
              activeIcon: Icons.logout_rounded,
              label: 'Sign Out',
              isActive: false,
              onTap: () => _signOut(context),
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      confirmColor: AppColors.error,
      icon: Icons.logout_rounded,
    );
    if (confirm == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? AppColors.error
        : widget.isActive
            ? AppColors.accent
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.sidebarActiveItem
                  : _hovered
                      ? AppColors.surfaceSecondary.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isActive ? widget.activeIcon : widget.icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: AppTextStyles.body.copyWith(
                    color: widget.isActive
                        ? AppColors.textPrimary
                        : color,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
