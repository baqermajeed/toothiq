const categoryService = require('../services/categoryService');

async function list(req, res, next) {
  try {
    const items = await categoryService.list();
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

async function listAdmin(req, res, next) {
  try {
    const items = await categoryService.listAll();
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const category = await categoryService.create(req.body);
    res.status(201).json({
      success: true,
      data: {
        id: category._id.toString(),
        nameAr: category.nameAr,
        icon: category.icon,
        order: category.order,
        isActive: category.isActive,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const category = await categoryService.update(req.params.id, req.body);
    res.json({
      success: true,
      data: {
        id: category._id.toString(),
        nameAr: category.nameAr,
        icon: category.icon,
        order: category.order,
        isActive: category.isActive,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function reorder(req, res, next) {
  try {
    const items = await categoryService.reorder(req.body.orderedIds);
    res.json({ success: true, data: items });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    await categoryService.remove(req.params.id);
    res.json({ success: true, data: { message: 'Category deleted' } });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  list,
  listAdmin,
  create,
  update,
  reorder,
  remove,
};
