import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../service_layer/services/preferences_storage.dart';
import '../../utils/app_colors.dart';
import '../../utils/storage_keys.dart';
import '../../widget/decorative_background.dart';
import '../../widget/my_text.dart';
import '../../widget/sparkle_icon.dart';
import '../auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  static const _slides = [
    _OnboardingSlideData(
      title: 'كل احتياجات عيادتك✨',
      description:
          'أجهزة وأدوات ومواد طب الأسنان من متاجر موثوقة تجتمع في تطبيق '
          'واحد بتجربة شراء سهلة ومنظمة.🪥🦷',
      icon: Icons.medical_services_outlined,
      accentColor: Color(0xFFB8E4E8),
      imageAsset: 'assets/onboarding/onboarding1.png',
    ),
    _OnboardingSlideData(
      title: 'تسوق بسهولة💫 ',
      description:
          'تصفح منتجات طب الأسنان من مصادر ومتاجر مختلفة، واختر ما يناسب '
          'عيادتك وأضفه إلى طلبك من مكان واحد.🛒',
      icon: Icons.storefront_outlined,
      accentColor: Color(0xFF9FD4D9),
      imageAsset: 'assets/onboarding/onboarding2.png',
    ),
    _OnboardingSlideData(
      title: 'توصيل سريع🚀',
      description:
          'صُمم التطبيق لتسهيل الطلب، من تصفح المنتجات إلى متابعة الحالة '
          'حتى يصل طلبك بسرعة وأمان إلى باب عيادتك.🚚',
      icon: Icons.local_shipping_outlined,
      accentColor: Color(0xFFC5E8EC),
      imageAsset: 'assets/onboarding/onboarding3.png',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await PreferencesStorage.instance.setBool(
      StorageKeys.onboardingCompleted,
      true,
    );
    Get.offAll(() => const LoginPage());
  }

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _carouselController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final isLast = _currentIndex == _slides.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: DecorativeBackground(
          child: Stack(
            children: [
              Positioned(
                top: 40.h,
                left: 20.w,
                child: SparkleIcon(size: 14.w, delay: 300.ms),
              ),
              Positioned(
                bottom: 100.h,
                right: 30.w,
                child: SparkleIcon(
                  size: 12.w,
                  filled: false,
                  delay: 500.ms,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 118.h),
                    SizedBox(
                      height: 156.h,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: MyText(
                                    slide.title,
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w800,
                                    textAlign: TextAlign.center,
                                    height: 1.4,
                                    maxLines: 2,
                                  ),
                                ),
                                SparkleIcon(size: 16.w, delay: 100.ms),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            MyText(
                              slide.description,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              textAlign: TextAlign.center,
                              height: 1.7,
                              maxLines: 4,
                            ),
                          ],
                        )
                            .animate(key: ValueKey('text_$_currentIndex'))
                            .fadeIn(duration: 400.ms)
                            .slideY(
                              begin: 0.15,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOutCubic,
                            ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _OnboardingCarousel(
                      carouselController: _carouselController,
                      slides: _slides,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                    ),
                    SizedBox(height: 24.h),
                    AnimatedSmoothIndicator(
                      activeIndex: _currentIndex.clamp(0, _slides.length - 1),
                      count: _slides.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.indicatorInactive,
                        dotHeight: 8.h,
                        dotWidth: 8.w,
                        expansionFactor: 4,
                        spacing: 8.w,
                        radius: 4.r,
                      ),
                      onDotClicked: (index) =>
                          _carouselController.animateToPage(index),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                      child: _OnboardingActionBar(
                        nextLabel: isLast ? 'ابدأ الآن' : 'التالي',
                        onNext: _onNext,
                        onSkip: _completeOnboarding,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 200.ms,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCarousel extends StatelessWidget {
  const _OnboardingCarousel({
    required this.carouselController,
    required this.slides,
    required this.onPageChanged,
  });

  final CarouselSliderController carouselController;
  final List<_OnboardingSlideData> slides;
  final ValueChanged<int> onPageChanged;

  static double get _cardWidth => 240.w;
  static double get _cardHeight => _cardWidth * (4 / 3);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: CarouselSlider.builder(
        carouselController: carouselController,
        itemCount: slides.length,
        options: CarouselOptions(
          height: _cardHeight + 24.h,
          viewportFraction: 0.62,
          enlargeCenterPage: true,
          enlargeFactor: 0.22,
          enableInfiniteScroll: false,
          padEnds: true,
          clipBehavior: Clip.none,
          onPageChanged: (index, _) => onPageChanged(index),
        ),
        itemBuilder: (context, index, _) {
          return Center(
            child: _CarouselCard(
              slide: slides[index],
              width: _cardWidth,
              height: _cardHeight,
            ),
          );
        },
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.slide,
    required this.width,
    required this.height,
  });

  final _OnboardingSlideData slide;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: slide.accentColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: slide.accentColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: slide.imageAsset != null
            ? Image.asset(
                slide.imageAsset!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Icon(
                    slide.icon,
                    size: 64.sp,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
      ),
    )
        .animate(key: ValueKey(slide.title))
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _OnboardingActionBar extends StatelessWidget {
  const _OnboardingActionBar({
    required this.nextLabel,
    required this.onNext,
    required this.onSkip,
  });

  final String nextLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(21.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21.r),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                flex: 65,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(21.r),
                  child: InkWell(
                    onTap: onNext,
                    borderRadius: BorderRadius.circular(21.r),
                    child: SizedBox(
                      height: 52.h,
                      child: Center(
                        child: MyText(
                          nextLabel,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 35,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSkip,
                    child: SizedBox(
                      height: 52.h,
                      child: Center(
                        child: MyText(
                          'تخطي',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.imageAsset,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? imageAsset;
}
