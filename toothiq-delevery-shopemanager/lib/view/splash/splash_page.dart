import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../utils/app_colors.dart';
import '../../widget/my_text.dart';
import '../auth/role_select_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final session = Get.find<SessionController>();
    while (session.isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    if (session.isAuthenticated.value && session.role.value != null) {
      session.openHomeForRole();
    } else {
      Get.offAll(() => const RoleSelectPage());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/icon/toothiqlogo.png',
                  width: 120.w,
                  height: 120.w,
                ),
                SizedBox(height: 16.h),
                Image.asset(
                  'assets/images/icon/toothiqtext.png',
                  width: 160.w,
                ),
                SizedBox(height: 12.h),
                MyText(
                  'متاجر · توصيل',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
