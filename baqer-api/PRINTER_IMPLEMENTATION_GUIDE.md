# دليل تطبيق عملية الطباعة باستخدام Sunmi Printer

## نظرة عامة
هذا الدليل يشرح بالتفصيل كيفية تطبيق عملية الطباعة الحرارية باستخدام طابعة Sunmi V2 SE في تطبيق Flutter. تم تنفيذ هذه الآلية لطباعة إيصالات الحجز تلقائياً عند تأكيد المواعيد الطبية.

---

## 1. المتطلبات الأساسية



- **الجهاز**: Sunmi V2 SE أو أي جهاز Sunmi يدعم الطابعة الحرارية المدمجة
- **Java/Kotlin**: لإعدادات Android

### ب. الحزم المطلوبة (Flutter Packages)

```yaml
dependencies:
  flutter:
    sdk: flutter
  sunmi_printer_plus: ^4.1.1  # حزمة التواصل مع طابعة Sunmi
  intl: ^0.19.0                # لتنسيق التاريخ والوقت
  get: ^4.6.5                  # لإدارة الحالة والتنقل (GetX)
```

---

## 2. إعداد المشروع

### أ. تحديث `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  sunmi_printer_plus: ^4.1.1
  intl: ^0.19.0

flutter:
  assets:
    - assets/icons/logo.png  # شعار للطباعة على الإيصال
```

### ب. تحديث `AndroidManifest.xml`

أضف الأذونات التالية في ملف `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- أذونات الوصول إلى الطابعة -->
    <uses-permission android:name="com.sunmi.printer.PRINT_PERMISSION" />
    
    <!-- إضافة queries للوصول إلى خدمة Sunmi Printer -->
    <queries>
        <package android:name="com.sunmi.printservice" />
        <intent>
            <action android:name="woyou.aidlservice.jiuiv5.IWoyouService" />
        </intent>
    </queries>
    
    <application>
        <!-- ... باقي الإعدادات -->
    </application>
</manifest>
```

---

## 3. هيكل الكود وتنظيم الملفات

### هيكل الملفات المطلوبة:

```
lib/
├── services/
│   └── sunmi_printer_service.dart    # خدمة الطباعة الرئيسية
├── widget/
│   └── loading_dialog.dart           # دايلوج التحميل (اختياري)
└── view/
    └── [your_page].dart              # الصفحة التي تستدعي الطباعة
```

---

## 4. إنشاء خدمة الطباعة (SunmiPrinterService)

### ملف: `lib/services/sunmi_printer_service.dart`

```dart
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class SunmiPrinterService {
  /// التحقق من توفر الطابعة
  static Future<bool> checkPrinterAvailable() async {
    try {
      final available = await SunmiPrinter.isAvailable();
      print(available ? '✅ Printer is available' : '⚠️ Printer is not available');
      return available;
    } catch (e) {
      print('❌ Error checking printer availability: $e');
      return false;
    }
  }

  /// تهيئة الطابعة
  static Future<bool> initPrinter() async {
    try {
      final available = await checkPrinterAvailable();
      if (!available) {
        print('⚠️ Printer is not available');
        return false;
      }
      
      await SunmiPrinter.initPrinter();
      print('✅ Printer initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing printer: $e');
      return false;
    }
  }

  /// طباعة نص مع محاذاة
  static Future<void> printText(
    String text, {
    SunmiPrintAlign align = SunmiPrintAlign.LEFT,
    int fontSize = 24,
    bool bold = false,
    bool underline = false,
  }) async {
    try {
      final style = SunmiTextStyle(
        align: align,
        fontSize: fontSize,
        bold: bold,
        underline: underline,
      );
      await SunmiPrinter.printText(text, style: style);
    } catch (e) {
      print('❌ Error printing text: $e');
    }
  }

  /// طباعة خط متقطع
  static Future<void> printDashedLine({SunmiPrintAlign align = SunmiPrintAlign.LEFT}) async {
    await printText('--------------------------------\n', align: align);
  }

  /// قطع الورق
  static Future<void> cutPaper() async {
    try {
      await SunmiPrinter.cutPaper();
    } catch (e) {
      print('❌ Error cutting paper: $e');
    }
  }

  /// طباعة الصورة
  static Future<void> printImage(Uint8List imageBytes, {SunmiPrintAlign align = SunmiPrintAlign.CENTER}) async {
    try {
      // استخدام setAlignment قبل طباعة الصورة للتأكد من التوسيط
      await SunmiPrinter.setAlignment(1); // CENTER = 1
      await Future.delayed(const Duration(milliseconds: 50));
      
      await SunmiPrinter.printImage(imageBytes, align: align);
      
      // إعادة تعيين المحاذاة بعد الطباعة
      await SunmiPrinter.setAlignment(1);
    } catch (e) {
      print('❌ Error printing image: $e');
    }
  }

  /// طباعة الإيصال الكامل
  static Future<bool> printReceipt({
    required String patientName,
    required String patientPhone,
    required int patientAge,
    required String doctorName,
    required String appointmentDate,
    required String appointmentTime,
    required double price,
    required String currency,
    required int queueNumber,
    String? appointmentId,
    String? doctorSpecialty,
    bool isPaid = false,
    String? customerServiceNumber,
  }) async {
    try {
      // التحقق من توفر الطابعة
      final available = await checkPrinterAvailable();
      if (!available) {
        print('⚠️ Printer is not available');
        return false;
      }

      // تهيئة الطابعة
      await initPrinter();

      // الحصول على الوقت الحالي (وقت الوصول) باللغة الإنجليزية
      final now = DateTime.now();
      final arrivalTime = DateFormat('h:mm a', 'en').format(now);

      // تنسيق التاريخ والوقت
      DateFormat dateFormat = DateFormat('yyyy/MM/dd', 'ar');
      DateFormat timeFormat = DateFormat('HH:mm', 'ar');
      
      DateTime? appointmentDateTime;
      try {
        appointmentDateTime = dateFormat.parse(appointmentDate);
      } catch (e) {
        // محاولة تنسيقات أخرى
        appointmentDateTime = DateTime.tryParse(appointmentDate);
      }

      String formattedDate = appointmentDate;
      if (appointmentDateTime != null) {
        formattedDate = dateFormat.format(appointmentDateTime);
      }

      String formattedTime = appointmentTime;
      try {
        final time = TimeOfDay.fromDateTime(DateTime.parse('1970-01-01 $appointmentTime'));
        formattedTime = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedTime = appointmentTime;
      }

      // ========== بدء الطباعة ==========

      // 1. شعار (صورة)
      await printText('\n', align: SunmiPrintAlign.CENTER);
      try {
        final ByteData bytes = await rootBundle.load('assets/icons/logo.png');
        final Uint8List list = bytes.buffer.asUint8List();
        await printImage(list, align: SunmiPrintAlign.CENTER);
      } catch (e) {
        print('⚠️ Failed to load or print logo image: $e');
        await printText('شعار\n', align: SunmiPrintAlign.CENTER, fontSize: 60, bold: true);
      }
      await printText('\n\n', align: SunmiPrintAlign.CENTER);

      // 2. عنوان النظام - متوسطة تماماً
      await printText('\n', align: SunmiPrintAlign.CENTER);
      await printText('نظام حجز المواعيد الطبية\n', align: SunmiPrintAlign.CENTER, fontSize: 33, bold: true);
      await printText('\n\n', align: SunmiPrintAlign.CENTER);

      // 3. خط متقطع
      await printDashedLine(align: SunmiPrintAlign.CENTER);
      await printText('\n', align: SunmiPrintAlign.CENTER);

      // 4. معلومات الطبيب
      await printText('$doctorName\n', align: SunmiPrintAlign.CENTER, fontSize: 33, bold: true);
      if (doctorSpecialty != null && doctorSpecialty.isNotEmpty) {
        await printText('$doctorSpecialty\n', align: SunmiPrintAlign.CENTER, fontSize: 30, bold: true);
      }
      await printText('\n\n', align: SunmiPrintAlign.CENTER);

      // 5. صندوق المعلومات الرئيسية (تسلسل الموعد والوقت)
      await printText('\n', align: SunmiPrintAlign.CENTER);
      await printText('$queueNumber\n', align: SunmiPrintAlign.CENTER, fontSize: 66, bold: true);
      await printText('\n\n', align: SunmiPrintAlign.CENTER);
      await printText('$formattedTime\n', align: SunmiPrintAlign.CENTER, fontSize: 36, bold: true);
      await printText('\n\n', align: SunmiPrintAlign.CENTER);

      // 6. تفاصيل إضافية
      await printText('وقت الوصل : $arrivalTime\n', align: SunmiPrintAlign.RIGHT, fontSize: 33, bold: true);
      await printText('التأريخ : $formattedDate\n', align: SunmiPrintAlign.RIGHT, fontSize: 33, bold: true);

      // حالة الدفع
      final paymentStatus = isPaid ? 'تم الدفع' : 'لم يدفع';
      await printText('المبلغ : $paymentStatus\n', align: SunmiPrintAlign.RIGHT, fontSize: 33, bold: true);
      await printText('\n\n', align: SunmiPrintAlign.LEFT);

      // 7. خط متقطع
      await printDashedLine(align: SunmiPrintAlign.CENTER);
      await printText('\n', align: SunmiPrintAlign.CENTER);

      // 8. دعوة لتحميل التطبيق
      await printText('نزل التطبيق واحجز موعدك القادم بكل سهولة\n', align: SunmiPrintAlign.CENTER, fontSize: 35, bold: true);

      // 9. رقم خدمة الزبائن
      final serviceNumber = customerServiceNumber ?? 'XXXX';
      await printText('رقم خدمة الزبائن $serviceNumber\n', align: SunmiPrintAlign.CENTER, fontSize: 26, bold: true);
      await printText('\n\n', align: SunmiPrintAlign.CENTER);

      // 10. خط متقطع
      await printDashedLine(align: SunmiPrintAlign.CENTER);
      await printText('\n', align: SunmiPrintAlign.CENTER);

      // 11. رسالة الختام
      await printText('نتمنى لكم دوام الصحة والعافية\n', align: SunmiPrintAlign.CENTER, fontSize: 30, bold: true);
      await printText('\n\n\n', align: SunmiPrintAlign.CENTER);

      // قطع الورق
      await cutPaper();

      print('✅ Receipt printed successfully');
      return true;
    } catch (e) {
      print('❌ Error printing receipt: $e');
      return false;
    }
  }
}
```

---

## 5. استخدام خدمة الطباعة في الصفحات

### أ. إنشاء دايلوج التحميل (اختياري)

ملف: `lib/widget/loading_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class LoadingDialog {
  static bool _isShowing = false;

  static Future<void> show({String message = 'جاري التحميل...'}) async {
    if (_isShowing) return;
    _isShowing = true;
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(width: 16.w),
              Text(message),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<void> hide() async {
    if (_isShowing) {
      _isShowing = false;
      if (Get.isDialogOpen == true) {
        try {
          final ctx = Get.overlayContext ?? Get.context;
          if (ctx != null) {
            Navigator.of(ctx, rootNavigator: true).pop();
          }
        } catch (e) {
          try {
            Get.back();
          } catch (_) {}
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }
}
```

### ب. استخدام الطباعة في الصفحة

مثال: `lib/view/appointment_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/sunmi_printer_service.dart';
import '../../widget/loading_dialog.dart';

class AppointmentPage extends StatelessWidget {
  const AppointmentPage({super.key});

  Future<void> _printReceipt() async {
    try {
      // عرض دايلوج التحميل
      await LoadingDialog.show(message: 'جاري الطباعة...');

      // استدعاء دالة الطباعة
      final success = await SunmiPrinterService.printReceipt(
        patientName: 'أحمد محمد',
        patientPhone: '07801234567',
        patientAge: 30,
        doctorName: 'د. علي أحمد',
        appointmentDate: '2026/01/08',
        appointmentTime: '14:00',
        price: 25000.0,
        currency: 'IQ',
        queueNumber: 5,
        appointmentId: 'appointment_123',
        doctorSpecialty: 'طب عام',
        isPaid: true,
        customerServiceNumber: '07801234567',
      );

      // إغلاق دايلوج التحميل
      await LoadingDialog.hide();

      // عرض رسالة النجاح/الفشل
      if (success) {
        Get.snackbar(
          'نجح',
          'تم طباعة الوصل بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'تحذير',
          'فشلت الطباعة. تأكد من أن الطابعة متصلة',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      await LoadingDialog.hide();
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء الطباعة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طباعة الإيصال')),
      body: Center(
        child: ElevatedButton(
          onPressed: _printReceipt,
          child: const Text('طباعة'),
        ),
      ),
    );
  }
}
```

---

## 6. آلية العمل (Flow)

### الخطوات بالترتيب:

1. **التحقق من توفر الطابعة**
   - استدعاء `SunmiPrinter.isAvailable()`
   - إرجاع `true` إذا كانت الطابعة متصلة ومتاحة

2. **تهيئة الطابعة**
   - استدعاء `SunmiPrinter.initPrinter()`
   - تحضير الطابعة لاستقبال الأوامر

3. **طباعة المحتوى**
   - طباعة الشعار (صورة أو نص)
   - طباعة العنوان الرئيسي
   - طباعة معلومات الطبيب
   - طباعة تفاصيل الموعد (الرقم، الوقت، التاريخ)
   - طباعة حالة الدفع
   - طباعة معلومات الاتصال

4. **قطع الورق**
   - استدعاء `SunmiPrinter.cutPaper()`
   - إنهاء عملية الطباعة

---

## 7. معالجة الأخطاء

### الأخطاء الشائعة وحلولها:

#### أ. الطابعة غير متصلة
```dart
if (!await SunmiPrinter.isAvailable()) {
  // عرض رسالة للمستخدم
  Get.snackbar('تحذير', 'الطابعة غير متصلة');
  return false;
}
```

#### ب. فشل تحميل الصورة
```dart
try {
  final ByteData bytes = await rootBundle.load('assets/icons/logo.png');
  final Uint8List list = bytes.buffer.asUint8List();
  await printImage(list);
} catch (e) {
  // استخدام نص بديل
  await printText('شعار\n', align: SunmiPrintAlign.CENTER);
}
```

#### ج. خطأ في التنسيق
```dart
try {
  final date = DateFormat('yyyy/MM/dd').parse(appointmentDate);
  formattedDate = DateFormat('yyyy/MM/dd').format(date);
} catch (e) {
  // استخدام التاريخ الأصلي
  formattedDate = appointmentDate;
}
```

---

## 8. أفضل الممارسات

### أ. التحقق دائماً من توفر الطابعة
- تحقق قبل كل عملية طباعة
- عرض رسالة واضحة للمستخدم إذا لم تكن متاحة

### ب. استخدام try-catch
- لف كل عملية طباعة بـ try-catch
- معالجة الأخطاء بشكل مناسب

### ج. تحسين تجربة المستخدم
- عرض دايلوج تحميل أثناء الطباعة
- إظهار رسائل نجاح/فشل واضحة
- عدم إيقاف العملية الرئيسية في حالة فشل الطباعة

### د. تنسيق النص
- استخدام `SunmiPrintAlign` للمحاذاة
- تجربة أحجام الخطوط المختلفة
- إضافة مسافات مناسبة بين العناصر

---

## 9. الاختبار

### خطوات الاختبار:

1. **اختبار على الجهاز الفعلي**
   - استخدام Sunmi V2 SE أو جهاز مشابه
   - التأكد من أن الطابعة متصلة ومشغلة

2. **اختبار السيناريوهات المختلفة**
   - طباعة ناجحة
   - طابعة غير متصلة
   - بيانات ناقصة
   - فشل تحميل الصورة

3. **اختبار الأداء**
   - وقت الاستجابة
   - استهلاك الذاكرة
   - استهلاك البطارية

---

## 10. الملاحظات المهمة

### أ. التوسيط على الطابعة الحرارية
- استخدام `SunmiPrintAlign.CENTER` مع `setAlignment(1)` قبل طباعة الصور
- تجربة أحجام خطوط مختلفة للتوسيط المثالي

### ب. دعم RTL (النصوص العربية)
- الحزمة تدعم RTL تلقائياً
- استخدام `TextDirection.rtl` في الواجهة

### ج. تنسيق التاريخ والوقت
- استخدام حزمة `intl` لتنسيق التاريخ
- تنسيق الوقت بالإنجليزية عند الحاجة

---

## 11. المراجع والمصادر

- **حزمة sunmi_printer_plus**: [pub.dev/packages/sunmi_printer_plus](https://pub.dev/packages/sunmi_printer_plus)
- **وثائق Sunmi SDK**: [sunmi.com](https://www.sunmi.com)
- **حزمة intl**: [pub.dev/packages/intl](https://pub.dev/packages/intl)

---

## 12. الدعم والمساعدة

في حالة وجود مشاكل:
1. تحقق من إعدادات `AndroidManifest.xml`
2. تأكد من أن الطابعة متصلة ومشغلة
3. راجع ملفات السجلات (logs) لاكتشاف الأخطاء
4. راجع وثائق الحزمة على pub.dev

---

**تاريخ الإنشاء**: 2026-01-07  
**الإصدار**: 1.0.0
