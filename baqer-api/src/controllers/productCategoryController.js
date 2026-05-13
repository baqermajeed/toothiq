const productCategoryService = require('../services/productCategoryService');
const { validateBulkBody } = require('../validators/productCategories');
const { badRequest } = require('../utils/errors');

async function list(req, res, next) {
  try {
    const shopId = req.params.shopId;
    const activeOnly = req.query.activeOnly !== 'false';
    const grouped = req.query.grouped === 'true';
    const includeProducts = req.query.includeProducts === 'true';
    const includeUnavailable = req.query.includeUnavailable === 'true';
    const categoryId = typeof req.query.categoryId === 'string' ? req.query.categoryId.trim() || undefined : undefined;
    const items = await productCategoryService.listByShop(shopId, {
      activeOnly,
      grouped,
      includeProducts,
      includeUnavailable,
      categoryId,
    });
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

async function bulkCreate(req, res, next) {
  try {
    const body = req.body && typeof req.body === 'object' ? req.body : {};
    const { error, value } = validateBulkBody(body);
    if (error) {
      const message = error.details ? error.details.map((d) => d.message).join('; ') : error.message;
      return next(badRequest(message || 'نص الفئات مطلوب', 'VALIDATION_ERROR'));
    }
    const text = typeof value.text === 'string' ? value.text.trim() : '';
    if (!text) {
      return next(badRequest('نص الفئات مطلوب', 'VALIDATION_ERROR'));
    }
    const result = await productCategoryService.bulkCreate(
      req.params.shopId,
      req.userId,
      req.userRoles || [],
      text
    );
    res.status(200).json({
      success: true,
      data: { created: result.created, failed: result.failed },
    });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const category = await productCategoryService.create(
      req.params.shopId,
      req.userId,
      req.body,
      req.userRoles || []
    );
    res.status(201).json({
      success: true,
      data: {
        id: category._id.toString(),
        shopId: category.shopId?.toString(),
        parentCategoryId: category.parentCategoryId?.toString() || null,
        nameAr: category.nameAr,
        order: category.order,
        isActive: category.isActive,
        image: category.image || null,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getById(req, res, next) {
  try {
    const category = await productCategoryService.getById(
      req.params.id,
      req.params.shopId
    );
    res.json({
      success: true,
      data: {
        id: category._id.toString(),
        shopId: category.shopId?.toString(),
        parentCategoryId: category.parentCategoryId?.toString() || null,
        nameAr: category.nameAr,
        order: category.order,
        isActive: category.isActive,
        image: category.image || null,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const category = await productCategoryService.update(
      req.params.id,
      req.params.shopId,
      req.userId,
      req.body,
      req.userRoles || []
    );
    res.json({
      success: true,
      data: {
        id: category._id.toString(),
        shopId: category.shopId?.toString(),
        parentCategoryId: category.parentCategoryId?.toString() || null,
        nameAr: category.nameAr,
        order: category.order,
        isActive: category.isActive,
        image: category.image || null,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await productCategoryService.remove(
      req.params.id,
      req.params.shopId,
      req.userId,
      req.userRoles || []
    );
    res.json({ success: true, data: { message: 'Product category deleted' } });
  } catch (err) {
    next(err);
  }
}

async function reorder(req, res, next) {
  try {
    const categoryIds = Array.isArray(req.body?.categoryIds)
      ? req.body.categoryIds.map((id) => String(id).trim()).filter(Boolean)
      : [];
    const items = await productCategoryService.reorder(
      req.params.shopId,
      req.userId,
      categoryIds,
      req.userRoles || []
    );
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, bulkCreate, create, getById, update, remove, reorder };
