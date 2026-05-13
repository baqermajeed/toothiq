# Qarep Delivery API

REST API for an order delivery system between customers, shops, drivers, and admin. Built with Node.js, Express, and MongoDB.

## Features

- **Auth**: Register, login, JWT (access + refresh tokens), logout
- **Users**: Profile (get/update) for authenticated users
- **Shops**: CRUD for shop owners; list with filters (category, isOpen, geo near)
- **Products**: CRUD per shop (nested under `/api/shops/:shopId/products`)
- **Orders**: Create order (customer), list by role, get by ID, update status (accept, preparing, on_the_way, delivered, cancel); delivery zone check before create
- **Delivery zones**: Polygon-based zones (per shop or global); check if a point is inside a zone
- **Admin**: List users/shops/orders, set user active/inactive, stats
- **Telegram**: Optional notifications to a Telegram bot when a new order is created or order status changes (driver accepts, shop/driver updates status)

## Tech stack

- Node.js 18+
- Express 4
- MongoDB + Mongoose
- JWT (jsonwebtoken), bcrypt, Helmet, express-rate-limit, Joi, Swagger (OpenAPI 3)

## Setup

1. Clone and install:

   ```bash
   cd qarep-api
   npm install
   ```

2. Copy env and configure:

   ```bash
   cp .env.example .env
   # Edit .env: MONGODB_URI, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET, etc.
   ```

3. Start MongoDB (local or Atlas).

4. Run:

   ```bash
   npm run dev    # development with watch
   npm start     # production
   ```

5. API base: `http://localhost:3000`  
   Swagger UI: `http://localhost:3000/api-docs`

## Firebase (إشعارات FCM)

للإشعارات الفورية، أضف في `.env`:

```
FIREBASE_CREDENTIALS_PATH=/path/to/your-firebase-adminsdk-xxxxx.json
```

أو استخدم `GOOGLE_APPLICATION_CREDENTIALS` بنفس المسار. احصل على الملف من [Firebase Console](https://console.firebase.google.com) → Project Settings → Service Accounts.

**تنبيه:** لا ترفع ملف اعتماد Firebase إلى Git — مُضاف تلقائياً في `.gitignore`.

## Environment variables

| Variable | Description |
|----------|-------------|
| `NODE_ENV` | `development` / `production` |
| `PORT` | Server port (default 3000) |
| `MONGODB_URI` | MongoDB connection string |
| `JWT_ACCESS_SECRET` | Secret for access tokens (مطلوب ≥32 حرف في الإنتاج) |
| `JWT_REFRESH_SECRET` | Secret for refresh tokens (مطلوب ≥32 حرف في الإنتاج) |
| `FIREBASE_CREDENTIALS_PATH` | مسار ملف اعتماد Firebase للإشعارات |
| `CORS_ORIGINS` | نطاقات مسموحة في الإنتاج (مفصولة بفاصلة) |
| `JWT_ACCESS_EXPIRES_IN` | e.g. `15m` |
| `JWT_REFRESH_EXPIRES_IN` | e.g. `7d` |
| `BCRYPT_ROUNDS` | Cost factor (default 12) |
| `RATE_LIMIT_*` | Rate limit options |
| `TELEGRAM_BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) (optional – leave empty to disable) |
| `TELEGRAM_CHAT_ID` | Chat/channel ID where notifications are sent (optional) |

## Roles

- **customer**: Place orders, view own orders, update profile
- **shop**: Create/update own shop and products, accept/prepare orders, assign driver
- **driver**: View assigned orders, mark on_the_way / delivered
- **admin**: Full access; manage users (active/inactive), view all entities, stats

## Telegram notifications

If `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are set in `.env`, the API sends notifications to your Telegram bot:

- **طلب جديد**: When a customer creates an order (with full details: shop, customer, items, total, delivery address).
- **تحديث حالة الطلب**: When order status changes (accepted, preparing, on_the_way, delivered, canceled), including who changed it (shop, driver, admin) and full order details.

Notifications are sent in the background and do not block or fail the API response.

## Delivery zones

- Zones are GeoJSON Polygons (per shop or global when `shopId` is null).
- Before creating an order, the API checks that `deliveryLocation` is inside an active zone for that shop (or a global zone).
- Use `GET /api/zones/check?lng=...&lat=...&shopId=...` to check if a point is deliverable.

## Tests

```bash
npm test
```

## Project structure

```
src/
  config/       env, db, constants
  models/       User, Shop, Product, Order, DeliveryZone
  middlewares/  auth, roles, validate, errorHandler, rateLimit
  routes/       auth, users, shops, products, orders, zones, admin
  controllers/
  services/
  validators/
  utils/        geo (polygon check), tokens, errors
  docs/         Swagger OpenAPI spec and setup
  app.js, server.js
```

## License

ISC
# qareyp-api
