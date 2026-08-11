import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../service_layer/services/preferences_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/storage_keys.dart';
import '../../widget/my_text.dart';
import '../auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController(viewportFraction: 0.78);
  int _currentIndex = 0;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      title: 'عنوان عنوان عنوان',
      description:
          'شرح شرح شرح شرح شرح شرح شرح شرح شرح شرح شرح شرح',
    ),
    _OnboardingSlideData(
      title: 'تسوق بسهولة',
      description:
          'تصفح آلاف منتجات طب الأسنان واختر ما يناسب عيادتك بكل راحة',
    ),
    _OnboardingSlideData(
      title: 'توصيل سريع',
      description:
          'نوصل طلبك بسرعة وأمان إلى باب عيادتك في أقرب وقت ممكن',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await PreferencesStorage.instance.setBool(
      StorageKeys.onboardingCompleted,
      true,
    );
    Get.offAll(() => const LoginPage());
  }

  void _goNext() {
    if (_currentIndex == _slides.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 32.h),
                MyText(
                  slide.title,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                MyText(
                  slide.description,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                  height: 1.6,
                  maxLines: 3,
                ),
                SizedBox(height: 32.h),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() {
                      _currentIndex = index;
                    }),
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double scale = 0.92;
                          if (_pageController.position.haveDimensions) {
                            final page =
                                _pageController.page ?? index.toDouble();
                            scale = (1 - (page - index).abs() * 0.08)
                                .clamp(0.92, 1.0);
                          }
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: _OnboardingCard(index: index),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _slides.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8.h,
                    dotWidth: 8.w,
                    spacing: 8.w,
                    expansionFactor: 3.2,
                    activeDotColor: AppColors.primary,
                    dotColor: AppColors.indicatorInactive,
                  ),
                ),
                SizedBox(height: 28.h),
                _BottomActionsBar(
                  isLastPage: _currentIndex == _slides.length - 1,
                  onSkip: _completeOnboarding,
                  onNext: _goNext,
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final int index;

  const _OnboardingCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardPlaceholder,
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 64.sp,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}

class _BottomActionsBar extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _BottomActionsBar({
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56.h,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: onNext,
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: MyText(
                    isLastPage ? 'ابدأ' : 'التالي',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Material(
              color: AppColors.skipBackground,
              borderRadius: BorderRadius.circular(16.r),
              child: InkWell(
                onTap: onSkip,
                borderRadius: BorderRadius.circular(16.r),
                child: Center(
                  child: MyText(
                    'تخطي',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  final String title;
  final String description;

  const _OnboardingSlideData({
    required this.title,
    required this.description,
  });
}
