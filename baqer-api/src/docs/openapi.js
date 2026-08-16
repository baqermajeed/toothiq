const env = require('../config/env');

const errorSchema = {
  type: 'object',
  properties: {
    success: { type: 'boolean', example: false },
    error: {
      type: 'object',
      properties: { code: { type: 'string' }, message: { type: 'string' } },
    },
  },
};

const userSchema = {
  type: 'object',
  properties: {
    _id: { type: 'string' },
    name: { type: 'string' },
    phone: { type: 'string' },
    governorateId: { type: 'string', example: 'baghdad', description: 'معرف المحافظة من GET /api/governorates' },
    clinicName: { type: 'string', nullable: true, description: 'اسم العيادة (اختياري)' },
    avatar: { type: 'string', nullable: true },
    roles: { type: 'array', items: { type: 'string' } },
    isActive: { type: 'boolean' },
    createdAt: { type: 'string', format: 'date-time' },
  },
};

const spec = {
  openapi: '3.0.0',
  info: {
    title: 'باقر API',
    version: '1.0.0',
    description: 'واجهة برمجة باقر — للعملاء، المحلات، والإدارة.',
  },
  // مسار نسبي: يعمل مع localhost أو IP أو النطاق الحقيقي في "Try it out"
  servers: [{ url: '/', description: 'Same origin as this page' }],
  tags: [
    { name: 'Health', description: 'فحص حالة الخادم' },
    { name: 'Governorates', description: 'المحافظات العراقية للتسجيل والواجهات' },
    { name: 'Auth', description: 'تسجيل، دخول، تحديث الرمز، خروج' },
    { name: 'Users', description: 'المستخدم الحالي' },
    { name: 'Shops', description: 'المحلات والتقييمات' },
    { name: 'Products', description: 'المنتجات والعروض' },
    { name: 'Categories', description: 'فئات المحلات العامة (تصنيف المحلات)' },
    { name: 'Catalog', description: 'كتالوج عام: أقسام → فرعية → منتجات من كل المحلات' },
    { name: 'Product Categories', description: 'أقسام المنتجات داخل كل محل' },
    { name: 'Banners', description: 'البانرات النشطة' },
    { name: 'Orders', description: 'الطلبات' },
    { name: 'Admin', description: 'لوحة الأدمن العامة' },
    { name: 'Admin Banners', description: 'إدارة البانرات' },
    { name: 'Admin Categories', description: 'إدارة فئات المحلات (CRUD وترتيب)' },
  ],
  components: {
    securitySchemes: {
      bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
    },
    schemas: {
      User: userSchema,
      Shop: {
        type: 'object',
        properties: {
          _id: { type: 'string' },
          name: { type: 'string' },
          description: { type: 'string' },
          category: { type: 'string' },
          location: { type: 'object' },
          deliveryFee: { type: 'number' },
          isOpen: { type: 'boolean' },
          rating: { type: 'number', minimum: 0, maximum: 5, example: 4.5 },
          ratingCount: { type: 'integer', minimum: 0, example: 27 },
          isActive: { type: 'boolean' },
        },
      },
      ShopReview: {
        type: 'object',
        properties: {
          _id: { type: 'string' },
          shopId: { type: 'string' },
          userId: {
            oneOf: [
              { type: 'string' },
              {
                type: 'object',
                properties: {
                  _id: { type: 'string' },
                  name: { type: 'string' },
                },
              },
            ],
          },
          rating: { type: 'integer', minimum: 1, maximum: 5, example: 5 },
          comment: { type: 'string', example: 'خدمة ممتازة وسريعة' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      Order: {
        type: 'object',
        properties: {
          _id: { type: 'string' },
          customerId: { type: 'string' },
          shopId: { type: 'string' },
          driverId: { type: 'string' },
          items: { type: 'array' },
          totalPrice: { type: 'number' },
          deliveryFee: { type: 'number' },
          status: { type: 'string' },
          deliveryLocation: { type: 'object' },
          notes: { type: 'string' },
          statusHistory: { type: 'array' },
          createdAt: { type: 'string', format: 'date-time' },
        },
      },
      Error: errorSchema,
      AdminSettings: {
        type: 'object',
        properties: {
          deliveryEnabled: { type: 'boolean' },
          deliveryPauseReason: { type: 'string' },
          globalDeliveryFee: { type: 'number' },
          useDashboardDeliveryFee: {
            type: 'boolean',
            description: 'عند true تُستخدم رسوم التوصيل من قاعدة البيانات حتى مع مصدر env',
          },
          platformSettingsSource: { type: 'string', enum: ['db', 'env'] },
          facebookUrl: { type: 'string' },
          instagramUrl: { type: 'string' },
          supportPhone: { type: 'string', description: 'رقم دعم واحد للتطبيق' },
          aboutUs: { type: 'string', description: 'نص «من نحن»' },
        },
      },
    },
  },
  paths: {
    '/api/health': {
      get: { summary: 'Health check', tags: ['Health'], responses: { 200: { description: 'OK' } } },
    },
    '/api/governorates': {
      get: {
        summary: 'قائمة المحافظات العراقية',
        description: 'معرفات ثابتة لعرضها في قوائم التسجيل والواجهات.',
        tags: ['Governorates'],
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    data: {
                      type: 'array',
                      items: {
                        type: 'object',
                        properties: {
                          id: { type: 'string', example: 'baghdad' },
                          nameAr: { type: 'string', example: 'بغداد' },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    '/api/auth/register': {
      post: {
        summary: 'Register',
        tags: ['Auth'],
        requestBody: {
          content: {
            'multipart/form-data': {
              schema: {
                type: 'object',
                required: ['name', 'phone', 'password', 'governorateId'],
                properties: {
                  name: { type: 'string' },
                  phone: { type: 'string', description: '١١ رقماً' },
                  password: { type: 'string', format: 'password' },
                  governorateId: {
                    type: 'string',
                    description: 'من القائمة: GET /api/governorates',
                    example: 'baghdad',
                  },
                  clinicName: { type: 'string', description: 'اسم العيادة (اختياري)' },
                  email: { type: 'string', format: 'email' },
                  avatar: { type: 'string', format: 'binary', description: 'صورة (اختياري) jpeg/png/webp' },
                  role: { type: 'string', enum: ['customer', 'shop'] },
                },
              },
            },
            'application/json': {
              schema: {
                type: 'object',
                required: ['name', 'phone', 'password', 'governorateId'],
                properties: {
                  name: { type: 'string' },
                  phone: { type: 'string' },
                  password: { type: 'string' },
                  governorateId: { type: 'string' },
                  clinicName: { type: 'string' },
                  email: { type: 'string' },
                  avatar: { type: 'string', description: 'مسار بعد الرفع — عادةً يُستخدم مع multipart' },
                  role: { type: 'string', enum: ['customer', 'shop'] },
                },
              },
            },
          },
        },
        responses: {
          201: { description: 'Created' },
          400: { description: 'Validation error', content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } } },
        },
      },
    },
    '/api/auth/login': {
      post: {
        summary: 'Login',
        tags: ['Auth'],
        requestBody: {
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['phone', 'password'],
                properties: { phone: { type: 'string' }, password: { type: 'string' } },
              },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' } },
      },
    },
    '/api/auth/refresh': {
      post: {
        summary: 'Refresh tokens',
        tags: ['Auth'],
        requestBody: {
          content: {
            'application/json': {
              schema: { type: 'object', required: ['refreshToken'], properties: { refreshToken: { type: 'string' } } },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 401: { description: 'Invalid refresh token' } },
      },
    },
    '/api/auth/logout': {
      post: { summary: 'Logout', tags: ['Auth'], security: [{ bearerAuth: [] }], responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' } } },
    },
    '/api/users/me': {
      get: { summary: 'Get current user', tags: ['Users'], security: [{ bearerAuth: [] }], responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' } } },
      patch: { summary: 'Update current user', tags: ['Users'], security: [{ bearerAuth: [] }], responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' } } },
    },
    '/api/shops': {
      get: { summary: 'List shops', tags: ['Shops'], parameters: [{ name: 'category', in: 'query' }, { name: 'isOpen', in: 'query' }, { name: 'page', in: 'query' }, { name: 'limit', in: 'query' }], responses: { 200: { description: 'OK' } } },
      post: { summary: 'Create shop', tags: ['Shops'], security: [{ bearerAuth: [] }], responses: { 201: { description: 'Created' }, 401: { description: 'Unauthorized' } } },
    },
    '/api/shops/top-rated': {
      get: {
        summary: 'Home feed: highest-rated shops',
        description: 'Pinned shops first (admin), then auto-ranked by rating. No duplicates.',
        tags: ['Shops'],
        parameters: [
          { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1, default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 50, default: 12 } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/products/offers': {
      get: {
        summary: 'Home feed: products on offer',
        tags: ['Products'],
        parameters: [
          { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1, default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 50, default: 12 } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/products/best-sellers': {
      get: {
        summary: 'Home feed: best-selling products',
        description: 'Pinned products first, then sold quantity from delivered orders.',
        tags: ['Products'],
        parameters: [
          { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1, default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 50, default: 12 } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/products/for-you': {
      get: {
        summary: 'Home feed: personalized products',
        description: 'Uses the caller order history when authenticated, else best-sellers/newest. Pins first.',
        tags: ['Products'],
        parameters: [
          { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1, default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 50, default: 12 } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/products/new': {
      get: {
        summary: 'Home feed: newest products',
        description: 'Pinned products first, then createdAt descending.',
        tags: ['Products'],
        parameters: [
          { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1, default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, default: 12 } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/shops/{id}': {
      get: { summary: 'Get shop by ID', tags: ['Shops'], parameters: [{ name: 'id', in: 'path', required: true }], responses: { 200: { description: 'OK' }, 404: { description: 'Not found' } } },
      patch: { summary: 'Update shop', tags: ['Shops'], security: [{ bearerAuth: [] }], parameters: [{ name: 'id', in: 'path', required: true }], responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } } },
    },
    '/api/shops/{id}/reviews': {
      get: {
        summary: 'List shop reviews',
        tags: ['Shops'],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
          { name: 'page', in: 'query', schema: { type: 'integer', minimum: 1, default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 100, default: 20 } },
        ],
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    data: {
                      type: 'object',
                      properties: {
                        items: { type: 'array', items: { $ref: '#/components/schemas/ShopReview' } },
                        pagination: {
                          type: 'object',
                          properties: {
                            page: { type: 'integer', example: 1 },
                            limit: { type: 'integer', example: 20 },
                            total: { type: 'integer', example: 120 },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
          404: { description: 'Shop not found' },
        },
      },
      post: {
        summary: 'Create or update user review for shop',
        description: 'المستخدم يضيف تقييم نجوم مع تعليق للمحل. إذا كان لديه تقييم سابق لنفس المحل يتم تحديثه.',
        tags: ['Shops'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['rating', 'comment'],
                properties: {
                  rating: { type: 'integer', minimum: 1, maximum: 5, example: 5 },
                  comment: { type: 'string', minLength: 1, maxLength: 1000, example: 'محل ممتاز والتوصيل سريع' },
                },
              },
            },
          },
        },
        responses: {
          201: {
            description: 'Created/updated',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    data: { $ref: '#/components/schemas/ShopReview' },
                  },
                },
              },
            },
          },
          400: { description: 'Validation error' },
          401: { description: 'Unauthorized' },
          403: { description: 'Owner cannot rate own shop' },
          404: { description: 'Shop not found' },
        },
      },
    },
    '/api/shops/{shopId}/products': {
      get: { summary: 'List products', tags: ['Products'], parameters: [{ name: 'shopId', in: 'path', required: true }], responses: { 200: { description: 'OK' } } },
      post: {
        summary: 'Create product',
        tags: ['Products'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'shopId', in: 'path', required: true }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['name', 'price'],
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  price: { type: 'number' },
                  image: { type: 'string' },
                  isAvailable: { type: 'boolean' },
                  categoryId: { type: 'string', nullable: true, description: 'القسم العام' },
                  subcategoryId: { type: 'string', nullable: true, description: 'القسم الفرعي' },
                  productCategoryId: { type: 'string', nullable: true },
                  offerPrice: { type: 'number', nullable: true },
                  offerEndsAt: { type: 'string', format: 'date-time', nullable: true },
                  productionDate: { type: 'string', format: 'date-time', nullable: true },
                  expiryDate: { type: 'string', format: 'date-time', nullable: true },
                },
              },
            },
          },
        },
        responses: { 201: { description: 'Created' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/shops/{shopId}/products/{id}': {
      get: { summary: 'Get product', tags: ['Products'], parameters: [{ name: 'shopId', in: 'path' }, { name: 'id', in: 'path' }], responses: { 200: { description: 'OK' }, 404: { description: 'Not found' } } },
      patch: {
        summary: 'Update product',
        tags: ['Products'],
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  name: { type: 'string' },
                  description: { type: 'string' },
                  price: { type: 'number' },
                  image: { type: 'string' },
                  isAvailable: { type: 'boolean' },
                  categoryId: { type: 'string', nullable: true, description: 'القسم العام' },
                  subcategoryId: { type: 'string', nullable: true, description: 'القسم الفرعي' },
                  productCategoryId: { type: 'string', nullable: true },
                  offerPrice: { type: 'number', nullable: true },
                  offerEndsAt: { type: 'string', format: 'date-time', nullable: true },
                  productionDate: { type: 'string', format: 'date-time', nullable: true },
                  expiryDate: { type: 'string', format: 'date-time', nullable: true },
                },
              },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
      delete: { summary: 'Delete product', tags: ['Products'], security: [{ bearerAuth: [] }], responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } } },
    },
    '/api/catalog/categories': {
      get: {
        summary: 'List catalog categories with product counts',
        description: 'tree=true يرجع الأقسام مع الفرعية للاختيار في التطبيق',
        tags: ['Catalog'],
        parameters: [
          { name: 'tree', in: 'query', schema: { type: 'boolean' }, description: 'إرجاع شجرة كاملة (أقسام + فرعية)' },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/catalog/categories/{categoryId}': {
      get: {
        summary: 'Category detail with subcategories that have products',
        tags: ['Catalog'],
        parameters: [{ name: 'categoryId', in: 'path', required: true }],
        responses: { 200: { description: 'OK' }, 404: { description: 'Not found' } },
      },
    },
    '/api/catalog/categories/{categoryId}/subcategories': {
      get: {
        summary: 'List subcategories for a category',
        tags: ['Catalog'],
        parameters: [
          { name: 'categoryId', in: 'path', required: true },
          { name: 'withCounts', in: 'query', schema: { type: 'boolean' } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/catalog/products': {
      get: {
        summary: 'List products across all shops by category/subcategory',
        tags: ['Catalog'],
        parameters: [
          { name: 'categoryId', in: 'query', schema: { type: 'string' } },
          { name: 'subcategoryId', in: 'query', schema: { type: 'string' } },
          { name: 'shopId', in: 'query', schema: { type: 'string' } },
          { name: 'q', in: 'query', schema: { type: 'string' } },
          { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
          { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
        ],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/shops/{shopId}/catalog': {
      get: {
        summary: 'Shop catalog for a main category (subcategories + products)',
        tags: ['Catalog'],
        parameters: [
          { name: 'shopId', in: 'path', required: true },
          { name: 'categoryId', in: 'query', required: true, schema: { type: 'string' } },
          { name: 'includeProducts', in: 'query', schema: { type: 'boolean' } },
        ],
        responses: { 200: { description: 'OK' }, 404: { description: 'Not found' } },
      },
    },
    '/api/categories': {
      get: {
        summary: 'List categories',
        tags: ['Categories'],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/shops/{shopId}/product-categories': {
      get: {
        summary: 'List shop product categories',
        tags: ['Product Categories'],
        parameters: [
          { name: 'shopId', in: 'path', required: true },
          { name: 'activeOnly', in: 'query', schema: { type: 'boolean', default: true }, description: 'false لإرجاع الأقسام المعطّلة أيضاً' },
          { name: 'grouped', in: 'query', schema: { type: 'boolean' }, description: 'عرض الفئات الرئيسية وبداخلها الأقسام' },
          { name: 'includeProducts', in: 'query', schema: { type: 'boolean' }, description: 'إرجاع منتجات كل قسم وكل منتجات الفئة' },
          { name: 'includeUnavailable', in: 'query', schema: { type: 'boolean' }, description: 'تضمين المنتجات غير المتاحة عند includeProducts=true' },
          { name: 'categoryId', in: 'query', schema: { type: 'string' }, description: 'فلترة النتائج على فئة رئيسية محددة' },
        ],
        responses: { 200: { description: 'OK' } },
      },
      post: {
        summary: 'Create shop product category',
        description: 'يمكن إرسال JSON أو multipart مع حقل image لرفع صورة القسم.',
        tags: ['Product Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'shopId', in: 'path', required: true }],
        requestBody: {
          required: true,
          content: {
            'multipart/form-data': {
              schema: {
                type: 'object',
                required: ['nameAr'],
                properties: {
                  nameAr: { type: 'string' },
                  parentCategoryId: { type: 'string', nullable: true, description: 'معرّف الفئة الرئيسية التي يتبع لها هذا القسم' },
                  subcategoryId: { type: 'string', nullable: true, description: 'ربط القسم بفرعي عام' },
                  order: { type: 'number' },
                  isActive: { type: 'boolean' },
                  image: { type: 'string', format: 'binary', description: 'jpeg/png/webp' },
                },
              },
            },
            'application/json': {
              schema: {
                type: 'object',
                required: ['nameAr'],
                properties: {
                  nameAr: { type: 'string' },
                  parentCategoryId: { type: 'string', nullable: true, description: 'معرّف الفئة الرئيسية التي يتبع لها هذا القسم' },
                  subcategoryId: { type: 'string', nullable: true, description: 'ربط القسم بفرعي عام' },
                  order: { type: 'number' },
                  isActive: { type: 'boolean' },
                  image: { type: 'string', nullable: true },
                },
              },
            },
          },
        },
        responses: { 201: { description: 'Created' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/shops/{shopId}/product-categories/reorder': {
      put: {
        summary: 'Reorder shop product categories',
        description: 'ترتيب أقسام المنتجات حسب ترتيب المعرفات في الطلب.',
        tags: ['Product Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'shopId', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['categoryIds'],
                properties: {
                  categoryIds: { type: 'array', items: { type: 'string' }, minItems: 1, description: 'ترتيب المعرفات من الأول للأخير' },
                },
              },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 400: { description: 'Validation error' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/shops/{shopId}/product-categories/bulk': {
      post: {
        summary: 'Bulk create product categories from text',
        description: 'إنشاء عدة أقسام من نص (مثلاً سطور أو مفصولة بفواصل). للمحل أو الأدمن.',
        tags: ['Product Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'shopId', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { type: 'object', required: ['text'], properties: { text: { type: 'string', description: 'نص يصف أسماء الأقسام' } } },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 400: { description: 'Validation error' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/shops/{shopId}/product-categories/{id}': {
      get: {
        summary: 'Get shop product category by ID',
        tags: ['Product Categories'],
        parameters: [
          { name: 'shopId', in: 'path', required: true, schema: { type: 'string' } },
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
        ],
        responses: { 200: { description: 'OK' }, 404: { description: 'Not found' } },
      },
      patch: {
        summary: 'Update shop product category',
        description: 'يمكن إرسال multipart مع حقل image لرفع صورة القسم.',
        tags: ['Product Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'shopId', in: 'path', required: true, schema: { type: 'string' } },
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
        ],
        requestBody: {
          content: {
            'multipart/form-data': {
              schema: {
                type: 'object',
                properties: {
                  nameAr: { type: 'string' },
                  parentCategoryId: { type: 'string', nullable: true },
                  order: { type: 'integer' },
                  isActive: { type: 'boolean' },
                  image: { type: 'string', format: 'binary' },
                },
              },
            },
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nameAr: { type: 'string' },
                  parentCategoryId: { type: 'string', nullable: true },
                  order: { type: 'integer' },
                  isActive: { type: 'boolean' },
                  image: { type: 'string', nullable: true },
                },
              },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 400: { description: 'Validation error' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
      delete: {
        summary: 'Delete shop product category',
        tags: ['Product Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'shopId', in: 'path', required: true, schema: { type: 'string' } },
          { name: 'id', in: 'path', required: true, schema: { type: 'string' } },
        ],
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
    },
    '/api/products/random-multi-shops': {
      get: {
        summary: 'Random products from multiple shops',
        description:
          'يرجع منتجات عشوائية مع تنويع بين عدة محلات. يدعم فلترة العروض والفئة، وفلترة الموقع عند توفر الإحداثيات.',
        tags: ['Products'],
        parameters: [
          { name: 'shopCount', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 20, default: 6 } },
          { name: 'perShop', in: 'query', schema: { type: 'integer', minimum: 1, maximum: 10, default: 2 } },
          { name: 'hasOffer', in: 'query', schema: { type: 'boolean' } },
          { name: 'productCategoryId', in: 'query', schema: { type: 'string' } },
        ],
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    data: {
                      type: 'object',
                      properties: {
                        items: {
                          type: 'array',
                          items: {
                            type: 'object',
                            properties: {
                              _id: { type: 'string' },
                              name: { type: 'string' },
                              description: { type: 'string' },
                              price: { type: 'number' },
                              image: { type: 'string' },
                              isAvailable: { type: 'boolean' },
                              shopId: { type: 'string' },
                              shopName: { type: 'string', nullable: true },
                              shopIsOpen: { type: 'boolean' },
                              productCategoryId: { type: 'string', nullable: true },
                              categoryName: { type: 'string', nullable: true },
                              offerPrice: { type: 'number', nullable: true },
                              isOnOffer: { type: 'boolean' },
                              offerEndsAt: { type: 'string', format: 'date-time', nullable: true },
                              productionDate: { type: 'string', format: 'date-time', nullable: true },
                              expiryDate: { type: 'string', format: 'date-time', nullable: true },
                            },
                          },
                        },
                        meta: {
                          type: 'object',
                          properties: {
                            shopsRequested: { type: 'integer', example: 6 },
                            shopsReturned: { type: 'integer', example: 4 },
                            perShop: { type: 'integer', example: 2 },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    '/api/banners': {
      get: {
        summary: 'List active banners',
        tags: ['Banners'],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/orders': {
      get: { summary: 'List orders (by role)', tags: ['Orders'], security: [{ bearerAuth: [] }], parameters: [{ name: 'status', in: 'query' }, { name: 'page', in: 'query' }, { name: 'limit', in: 'query' }], responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' } } },
      post: { summary: 'Create order', tags: ['Orders'], security: [{ bearerAuth: [] }], requestBody: { content: { 'application/json': { schema: { type: 'object', required: ['shopId', 'items', 'deliveryLocation'], properties: { shopId: { type: 'string' }, items: { type: 'array' }, deliveryLocation: { type: 'object' }, notes: { type: 'string' } } } } } }, responses: { 201: { description: 'Created' }, 400: { description: 'Bad request' }, 401: { description: 'Unauthorized' } } },
    },
    '/api/orders/{id}': {
      get: { summary: 'Get order by ID', tags: ['Orders'], security: [{ bearerAuth: [] }], parameters: [{ name: 'id', in: 'path', required: true }], responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } } },
    },
    '/api/orders/{id}/status': {
      patch: { summary: 'Update order status', tags: ['Orders'], security: [{ bearerAuth: [] }], parameters: [{ name: 'id', in: 'path', required: true }], requestBody: { content: { 'application/json': { schema: { type: 'object', required: ['status'], properties: { status: { type: 'string', enum: ['pending', 'accepted', 'preparing', 'on_the_way', 'delivered', 'canceled', 'postponed'] }, cancelReason: { type: 'string' }, postponedReason: { type: 'string' } } } } } }, responses: { 200: { description: 'OK' }, 400: { description: 'Invalid transition' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } } },
    },
    '/api/admin/users': {
      get: {
        summary: 'List users (admin)',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'page', in: 'query' },
          { name: 'limit', in: 'query' },
          { name: 'isActive', in: 'query' },
          { name: 'role', in: 'query' },
          { name: 'q', in: 'query', description: 'Search by name, phone, or email' },
        ],
        responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/admin/shops': {
      get: { summary: 'List shops (admin)', tags: ['Admin'], security: [{ bearerAuth: [] }], parameters: [{ name: 'page', in: 'query' }, { name: 'limit', in: 'query' }, { name: 'isActive', in: 'query' }], responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' } } },
    },
    '/api/admin/orders': {
      get: { summary: 'List orders (admin)', tags: ['Admin'], security: [{ bearerAuth: [] }], parameters: [{ name: 'page', in: 'query' }, { name: 'limit', in: 'query' }, { name: 'status', in: 'query' }], responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' } } },
    },
    '/api/admin/stats': {
      get: { summary: 'Get stats (admin)', tags: ['Admin'], security: [{ bearerAuth: [] }], responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' } } },
    },
    '/api/admin/settings': {
      get: {
        summary: 'Get admin settings',
        description: 'إعدادات المنصة: التوصيل، رسوم التوصيل، التواصل، و«من نحن».',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    data: { $ref: '#/components/schemas/AdminSettings' },
                  },
                },
              },
            },
          },
          401: { description: 'Unauthorized' },
          403: { description: 'Forbidden (admin only)' },
        },
      },
      patch: {
        summary: 'Update admin settings',
        description: 'تحديث جزئي لأي من حقول إعدادات المنصة (توصيل، روابط، دعم، من نحن).',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  deliveryEnabled: { type: 'boolean' },
                  deliveryPauseReason: { type: 'string' },
                  globalDeliveryFee: { type: 'number', minimum: 0 },
                  facebookUrl: { type: 'string' },
                  instagramUrl: { type: 'string' },
                  supportPhone: { type: 'string' },
                  aboutUs: { type: 'string' },
                },
              },
            },
          },
        },
        responses: {
          200: {
            description: 'OK',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    success: { type: 'boolean', example: true },
                    data: { $ref: '#/components/schemas/AdminSettings' },
                  },
                },
              },
            },
          },
          400: { description: 'Validation error' },
          401: { description: 'Unauthorized' },
          403: { description: 'Forbidden (admin only)' },
        },
      },
    },
    '/api/admin/users/{id}/active': {
      patch: { summary: 'Set user active/inactive (admin)', tags: ['Admin'], security: [{ bearerAuth: [] }], parameters: [{ name: 'id', in: 'path', required: true }], requestBody: { content: { 'application/json': { schema: { type: 'object', required: ['isActive'], properties: { isActive: { type: 'boolean' } } } } } }, responses: { 200: { description: 'OK' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } } },
    },
    '/api/admin/home-sections': {
      get: {
        summary: 'List pinned items for a home section',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'section',
            in: 'query',
            required: true,
            schema: { type: 'string', enum: ['best_sellers', 'for_you', 'new', 'top_rated'] },
          },
        ],
        responses: { 200: { description: 'OK' } },
      },
      post: {
        summary: 'Pin a product or shop to a home section',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        responses: { 201: { description: 'Created' }, 409: { description: 'Already pinned' } },
      },
    },
    '/api/admin/home-sections/{id}': {
      patch: {
        summary: 'Update pin order or active state',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true }],
        responses: { 200: { description: 'OK' } },
      },
      delete: {
        summary: 'Remove a home section pin',
        tags: ['Admin'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true }],
        responses: { 200: { description: 'OK' } },
      },
    },
    '/api/admin/banners': {
      get: {
        summary: 'List banners (admin)',
        tags: ['Admin Banners'],
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
      post: {
        summary: 'Create banner (admin)',
        tags: ['Admin Banners'],
        security: [{ bearerAuth: [] }],
        responses: { 201: { description: 'Created' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/admin/banners/{id}': {
      patch: {
        summary: 'Update banner (admin)',
        tags: ['Admin Banners'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true }],
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
      delete: {
        summary: 'Delete banner (admin)',
        tags: ['Admin Banners'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true }],
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
    },
    '/api/admin/categories': {
      get: {
        summary: 'List shop categories (admin)',
        description: 'جميع فئات المحلات بما فيها غير النشطة.',
        tags: ['Admin Categories'],
        security: [{ bearerAuth: [] }],
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
      post: {
        summary: 'Create shop category (admin)',
        tags: ['Admin Categories'],
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['nameAr'],
                properties: {
                  nameAr: { type: 'string', minLength: 1, maxLength: 100 },
                  icon: { type: 'string', maxLength: 50 },
                  order: { type: 'integer', minimum: 0 },
                  isActive: { type: 'boolean' },
                },
              },
            },
          },
        },
        responses: { 201: { description: 'Created' }, 400: { description: 'Validation error' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/admin/categories/reorder': {
      patch: {
        summary: 'Reorder shop categories (admin)',
        tags: ['Admin Categories'],
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['orderedIds'],
                properties: {
                  orderedIds: { type: 'array', items: { type: 'string' }, minItems: 1, description: 'معرفات MongoDB بالترتيب المطلوب' },
                },
              },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 400: { description: 'Validation error' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' } },
      },
    },
    '/api/admin/categories/{id}': {
      patch: {
        summary: 'Update shop category (admin)',
        tags: ['Admin Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: {
          content: {
            'application/json': {
              schema: {
                type: 'object',
                minProperties: 1,
                properties: {
                  nameAr: { type: 'string', minLength: 1, maxLength: 100 },
                  icon: { type: 'string', maxLength: 50 },
                  order: { type: 'integer', minimum: 0 },
                  isActive: { type: 'boolean' },
                },
              },
            },
          },
        },
        responses: { 200: { description: 'OK' }, 400: { description: 'Validation error' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
      delete: {
        summary: 'Delete shop category (admin)',
        tags: ['Admin Categories'],
        security: [{ bearerAuth: [] }],
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: { 200: { description: 'OK' }, 401: { description: 'Unauthorized' }, 403: { description: 'Forbidden' }, 404: { description: 'Not found' } },
      },
    },
  },
};

module.exports = spec;
