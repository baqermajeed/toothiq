# إعداد إشعارات FCM على iOS

حتى تصل إشعارات FCM إلى أجهزة **iOS** يجب إكمال الخطوة التالية (بالإضافة إلى إعداد المشروع المحلي الذي تم تطبيقه).

## الخطوة الأساسية: رفع مفتاح APNs في Firebase

بدون هذه الخطوة **لن تصل أي إشعارات** إلى أجهزة iPhone/iPad لأن FCM يعتمد على **Apple Push Notification service (APNs)** للتوصيل على iOS.

### 1. إنشاء APNs Key في Apple Developer

1. ادخل إلى [Apple Developer](https://developer.apple.com/account/) → **Certificates, Identifiers & Profiles** → **Keys**.
2. اضغط **+** لإنشاء مفتاح جديد.
3. اختر اسمًا للمفتاح (مثل: `Qaryp APNs Key`).
4. فعّل **Apple Push Notifications service (APNs)**.
5. اضغط **Continue** ثم **Register**.
6. **حمّل الملف `.p8`** واحفظه في مكان آمن (لا يمكن تحميله مرة ثانية).
7. سجّل:
   - **Key ID**
   - **Team ID** (من صفحة العضوية)
   - **Bundle ID** للتطبيق (مثل: `com.infintiy.qarrep`)

### 2. رفع المفتاح في Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com/) → مشروعك.
2. اضغط أيقونة **الإعدادات** → **Project settings**.
3. تبويب **Cloud Messaging**.
4. في قسم **Apple app configuration**:
   - اختر تطبيق iOS (أو أضف تطبيق iOS إذا لم يكن مضافًا).
   - في **APNs Authentication Key** اضغط **Upload**.
   - ارفع ملف **.p8**.
   - أدخل **Key ID** و **Team ID** و **Bundle ID**.
5. احفظ التغييرات.

بعد رفع المفتاح، انتظر دقائق ثم جرّب إرسال إشعار تجريبي إلى جهاز iOS.

---

## ما تم إعداده في المشروع

- **Runner.entitlements** (للـ Debug): تفعيل Push مع `aps-environment: development`.
- **Runner-Release.entitlements** (للـ Release/Profile): `aps-environment: production` للنشر و TestFlight.
- **Info.plist**: `UIBackgroundModes` → `remote-notification` (كان مضافًا مسبقًا).
- **AppDelegate**: استدعاء `registerForRemoteNotifications()` لتسجيل الجهاز مع APNs.

## ملاحظات

- **development**: للاختبار على جهاز مرتبط بـ Xcode أو بناء Debug.
- **production**: مطلوب للإشعارات على بناء Release و TestFlight و App Store.
- تأكد أن **Bundle ID** في Xcode يطابق الـ Bundle ID المُسجّل في Firebase و Apple.
