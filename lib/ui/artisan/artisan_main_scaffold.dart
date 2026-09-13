import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_pending_screen.dart';
import 'package:warisan_kita/ui/artisan/artisan_application_approved_screen.dart';
import 'package:warisan_kita/ui/artisan/artisan_dashboard_tab.dart';
import 'package:warisan_kita/ui/artisan/artisan_settings_screen.dart';
import 'package:warisan_kita/ui/artisan/artisan_suspended_screen.dart';
import 'package:warisan_kita/ui/artisan/profile_builder_tab.dart';
import 'package:warisan_kita/ui/core/account_suspended_screen.dart';
import 'package:warisan_kita/ui/core/live_forum_tab.dart';
import 'package:warisan_kita/viewmodels/auth_viewmodel.dart';

class ArtisanMainScaffold extends StatefulWidget {
  final bool enableLivePolling;
  const ArtisanMainScaffold({super.key, this.enableLivePolling = true});

  @override
  State<ArtisanMainScaffold> createState() => _ArtisanMainScaffoldState();
}

class _ArtisanMainScaffoldState extends State<ArtisanMainScaffold> {
  int _currentIndex = 0;
  bool _hasSeenApprovalScreen = false;
  bool _isLoading = true;
  Timer? _statusPollTimer;

  final List<Widget> _tabs = const [
    ArtisanDashboardTab(),
    ProfileBuilderTab(),
    LiveForumTab(),
    ArtisanSettingsScreen(),
  ];
  
  @override
  void initState() {
    super.initState();
    _checkApprovalStatus();
    if (widget.enableLivePolling) {
      _statusPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) {
          final auth = context.read<AuthViewModel>();
          if (auth.currentUser != null && !auth.currentUser!.isSuspended) {
            auth.refreshCurrentUser();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _checkApprovalStatus() async {
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'hasSeenApproval_${user.id}';
      setState(() {
        _hasSeenApprovalScreen = prefs.getBool(key) ?? false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissApprovalScreen() async {
    final authVM = context.read<AuthViewModel>();
    final user = authVM.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenApproval_${user.id}', true);
    }
    setState(() {
      _hasSeenApprovalScreen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    // Security Guard 1: Account-level suspension blocks entire account
    if (user != null && (user.isSuspended || user.status == 'SUSPENDED')) {
      return const AccountSuspendedScreen();
    }

    if (user == null) {
      if (!authVM.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              ModalRoute.of(context)?.isCurrent == true &&
              context.read<AuthViewModel>().currentUser == null) {
            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Security Guard 2: Non-artisan accounts (Tourists) are not authorized to view the Artisan Scaffold
    final bool hasArtisanAccess = user.isApprovedArtisan ||
        user.isPendingArtisan ||
        user.isRejectedArtisan ||
        user.isArtisanStudioSuspended ||
        user.role == 'Artisan' ||
        user.role == 'Master Artisan' ||
        user.roles.contains('Artisan') ||
        user.roles.contains('Master Artisan') ||
        user.isDualRole;

    if (!hasArtisanAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context, rootNavigator: true).pushReplacementNamed('/tourist');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Security Guard 3: If Artisan Studio is suspended, immediately eject from artisan tabs
    if (user.isArtisanStudioSuspended) {
      return const ArtisanStudioSuspendedScreen();
    }

    if (user != null && !user.isApprovedArtisan && (user.isPendingArtisan || user.isRejectedArtisan || user.status == 'PENDING_APPROVAL' || user.status == 'PENDING' || user.status == 'REJECTED' || user.artisanStatus?.toUpperCase() == 'REJECTED')) {
      return const ArtisanApplicationPendingScreen();
    }
    
    // Show one-time celebratory screen
    if (user != null && user.isApprovedArtisan && !_hasSeenApprovalScreen) {
      return ArtisanApplicationApprovedScreen(
        onContinue: _dismissApprovalScreen,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF041412) : const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D2825) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E3A34) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF0D2825) : Colors.white,
          selectedItemColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFFD97706),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'Edit Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'Forum',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
