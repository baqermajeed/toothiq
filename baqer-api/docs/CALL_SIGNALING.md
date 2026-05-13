# تكامل خادم المكالمات (إشارة WebRTC)

## ما يوفّره qarep-api

- **`GET /api/calls/config`** (بعد `Authorization: Bearer …`): يعيد `signalingWsUrl` و`iceServers` من متغيرات البيئة، حتى لا يُخزَّن عنوان خادم الإشارة أو مفاتيح API في تطبيقات الموبايل.
- **`GET /api/orders/:id/call-targets`**: يعيد `{ customerUserId, driverUserId }` لمن له صلاحية رؤية الطلب.
- حقول مسطحة على الطلب: **`customerUserId`**, **`driverUserId`** (إلى جانب الكائنات المعبأة).

## متغيرات البيئة (انظر `.env.example`)

- `CALL_SIGNALING_WS_URL` — عنوان WebSocket العام للعملاء، مثل `wss://your-domain/ws`.
- `CALL_WEBRTC_ICE_JSON` — مصفوفة JSON لخوادم ICE/TURN (اختياري).

## مصادقة WebSocket على VPS

إن كان خادم الـ Go يطلب **API Key** على ترقية WebSocket، **لا** تضع المفتاح في التطبيق. الخيارات الموصى بها:

1. جعل مسار WebSocket عاماً للجلسات المُسجَّلة برسالة `register` فقط (كما في التكامل الحالي)، والاكتفاء بـ API Key لـ HTTP الإداري فقط.
2. أو إضافة في خادم الـ Go نقطة توليد **توكن قصير العمر** يستدعيها `qarep-api` بمفتاح السيرفر، ويُمرَّر التوكن للعميل كـ query آمن نسبياً (`?token=`).

## FCM

خادم المكالمات يجب أن يستخدم نفس مشروع Firebase المناسب لكل تطبيق (سائق / عميل) عند إرسال `incoming_call` و`call_cancelled` مع `caller_id` بالصيغة `driver:<id>` أو `customer:<id>`.
