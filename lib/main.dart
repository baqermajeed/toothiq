import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'bindings/home_binding.dart';
import 'controller/main_controller.dart';
import 'controller/session_controller.dart';
import 'service_layer/services/get_storage_service.dart';
import 'utils/app_colors.dart';
import 'view/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await GetStorageService().init();

  runApp(const DentalApp());
}

class DentalApp extends StatelessWidget {
  const DentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'متجر طب الأسنان',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar'),
          fallbackLocale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Expo Arabic',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
            scaffoldBackgroundColor: AppColors.background,
          ),
          home: const SplashPage(),
          initialBinding: BindingsBuilder(() {
            Get.put(SessionController(), permanent: true);
            Get.put(MainController(), permanent: true);
            HomeBinding().dependencies();
          }),
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 220),
        );
      },
    );
  }
}
