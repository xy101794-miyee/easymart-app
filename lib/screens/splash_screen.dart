import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/easymart_provider.dart';
import '../data/models.dart';
import 'auth/login_screen.dart';
import 'customer/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2000), () async {
      final provider = context.read<EasymartProvider>();
      await provider.initialize();
      if (!mounted) return;
      final userId = provider.currentUser;
      if (userId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else if (provider.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller),
              child: SizedBox(
                width: 200,
                height: 200,
                child: SvgPicture.asset('assets/images/easymart_logo.svg'),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppStrings.tagline,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: AppColors.orange,
                backgroundColor: AppColors.orangeSoft,
              ),
            )
          ],
        ),
      ),
    );
  }
}
