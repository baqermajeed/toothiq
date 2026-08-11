const catalogService = require('../services/catalogService');

async function listCategories(req, res, next) {
  try {
    const tree = req.query.tree === 'true';
    const data = tree ? await catalogService.getTaxonomyTree() : await catalogService.listCategories();
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function getCategory(req, res, next) {
  try {
    const data = await catalogService.getCategoryDetail(req.params.categoryId);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function listSubcategories(req, res, next) {
  try {
    const withCounts = req.query.withCounts === 'true';
    const data = await catalogService.listSubcategoriesByCategory(req.params.categoryId, {
      activeOnly: req.query.activeOnly !== 'false',
      withCounts,
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function listBrands(req, res, next) {
  try {
    const withCounts = req.query.withCounts === 'true';
    const data = await catalogService.listBrandsByCategory(req.params.categoryId, {
      activeOnly: req.query.activeOnly !== 'false',
      withCounts,
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function listProducts(req, res, next) {
  try {
    const filters = {
      page: req.query.page,
      limit: req.query.limit,
      categoryId: req.query.categoryId,
      subcategoryId: req.query.subcategoryId,
      brandId: req.query.brandId,
      q: req.query.q,
      shopId: req.query.shopId,
    };
    const result = await catalogService.listProducts(filters);
    res.json({ success: true, data: result });
  } catch (err) {
    next(err);
  }
}

async function getShopCatalog(req, res, next) {
  try {
    const categoryId = typeof req.query.categoryId === 'string' ? req.query.categoryId.trim() : '';
    const data = await catalogService.getShopCatalog(req.params.shopId, categoryId, {
      includeProducts: req.query.includeProducts === 'true',
      includeUnavailable: req.query.includeUnavailable === 'true',
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listCategories,
  getCategory,
  listSubcategories,
  listBrands,
  listProducts,
  getShopCatalog,
};
