import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controller/session_controller.dart';
import '../../service_layer/services/preferences_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/storage_keys.dart';
import '../../widget/my_text.dart';
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
                    size: 56.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 24.h),
                MyText(
                  'متجر طب الأسنان',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
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
    );
  }
}
