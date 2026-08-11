const path = require('path');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const env = require('./config/env');
//س

//de3
const errorHandler = require('./middlewares/errorHandler');
const { notFound } = require('./utils/errors');
const rateLimiter = require('./middlewares/rateLimit');
const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const shopsRoutes = require('./routes/shops');
const productsRoutes = require('./routes/products');
const productCategoriesRoutes = require('./routes/productCategories');
const productSearchRoutes = require('./routes/productSearch');
const ordersRoutes = require('./routes/orders');
const callsRoutes = require('./routes/calls');
const catalogRoutes = require('./routes/catalog');
const categoriesRoutes = require('./routes/categories');
const shopCatalogRoutes = require('./routes/shopCatalog');
const adminRoutes = require('./routes/admin');
const appContactRoutes = require('./routes/appContact');
const appVersionRoutes = require('./routes/appVersion');
const deviceRoutes = require('./routes/device');
const bannersRoutes = require('./routes/banners');
const publicAppRoutes = require('./routes/publicApp');
const discountCodesRoutes = require('./routes/discountCodes');
const governoratesRoutes = require('./routes/governorates');
const shopTaxonomyRoutes = require('./routes/shopTaxonomy');
const driverRoutes = require('./routes/driver');
const setupSwagger = require('./docs/setup');

const app = express();

// ضروري عند تشغيل الـ API خلف بروكسي (مثل Nginx): يثق بـ X-Forwarded-For لـ rate-limit وعنوان العميل
app.set('trust proxy', 1);

// بدون تعطيل upgrade-insecure-requests: المتصفح يحوّل أصول Swagger (./swagger-ui.css) إلى HTTPS
// بينما الخادم يعرض HTTP فقط → net::ERR_SSL_PROTOCOL_ERROR ويفشل /api-docs على IP أو HTTP.
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        upgradeInsecureRequests: null,
      },
    },
    crossOriginOpenerPolicy: false,
    originAgentCluster: false,
  })
);
const corsOriginsList = env.corsOrigins
  ? env.corsOrigins.split(',').map((o) => o.trim()).filter(Boolean)
  : [];
const corsOptions = corsOriginsList.length > 0 ? { origin: corsOriginsList } : {};
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(rateLimiter.general);
app.use('/api/governorates', governoratesRoutes);
setupSwagger(app);
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
app.use('/api/auth', rateLimiter.auth, authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/shops/:shopId/products', productsRoutes);
app.use('/api/shops/:shopId/product-categories', productCategoriesRoutes);
app.use('/api/shops/:shopId/taxonomy', shopTaxonomyRoutes);
app.use('/api/shops/:shopId/catalog', shopCatalogRoutes);
app.use('/api/products', productSearchRoutes);
app.use('/api/shops', shopsRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/discount-codes', discountCodesRoutes);
app.use('/api/calls', callsRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/catalog', catalogRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/app-contact', appContactRoutes);
app.use('/api/app-version', appVersionRoutes);
app.use('/api/banners', bannersRoutes);
app.use('/api/public', publicAppRoutes);
app.use('/qareep', deviceRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use((req, res, next) => next(notFound('Route not found')));

app.use(errorHandler);

module.exports = app;
