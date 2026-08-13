import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../service_layer/services/preferences_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/storage_keys.dart';
import '../../widget/decorative_background.dart';
import '../../widget/my_text.dart';
import '../../widget/sparkle_icon.dart';
import '../auth/login_page.dart';
import '../main_page.dart';
import '../onboarding/onboarding_page.dart';

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
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final session = Get.find<SessionController>();
    while (session.isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    final prefs = PreferencesStorage.instance;
    final completed = prefs.getBool(StorageKeys.onboardingCompleted) ?? false;

    if (session.isAuthenticated) {
      MainPage.open();
      return;
    }

    if (completed) {
      Get.offAll(() => const LoginPage());
    } else {
      Get.offAll(() => const OnboardingPage());
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
      body: DecorativeBackground(
        child: Stack(
          children: [
            Positioned(
              top: 48.h,
              left: 24.w,
              child: SparkleIcon(size: 14.w, delay: 200.ms),
            ),
            Positioned(
              top: 88.h,
              right: 32.w,
              child: SparkleIcon(size: 12.w, filled: false, delay: 400.ms),
            ),
            Positioned(
              top: 200.h,
              left: 48.w,
              child: SparkleIcon(size: 10.w, delay: 600.ms),
            ),
            Positioned(
              bottom: 140.h,
              right: 28.w,
              child: SparkleIcon(size: 16.w, delay: 300.ms),
            ),
            Positioned(
              bottom: 88.h,
              left: 36.w,
              child: SparkleIcon(size: 12.w, filled: false, delay: 500.ms),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Align(
                  alignment: const Alignment(0, -0.28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/icon/toothiq_logo_auth.png',
                        width: 140.w,
                        height: 140.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20.h),
                      Image.asset(
                        'assets/images/icon/toothiqtext.png',
                        height: 28.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 8.h),
                      MyText(
                        'منتجات احترافية لعيادتك',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 48.h),
                      SizedBox(
                        width: 32.w,
                        height: 32.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
