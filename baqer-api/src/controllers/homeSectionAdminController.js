const homeFeedService = require('../services/homeFeedService');
const { HomeSectionPin } = require('../models');
const { badRequest } = require('../utils/errors');

async function list(req, res, next) {
  try {
    const section = String(req.query.section || '').trim();
    if (!HomeSectionPin.SECTIONS.includes(section)) {
      return next(badRequest('حدد قسماً صالحاً'));
    }
    const data = await homeFeedService.listPins(section);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function create(req, res, next) {
  try {
    const pin = await homeFeedService.createPin(req.body || {});
    res.status(201).json({ success: true, data: pin });
  } catch (err) {
    next(err);
  }
}

async function update(req, res, next) {
  try {
    const pin = await homeFeedService.updatePin(req.params.id, req.body || {});
    res.json({ success: true, data: pin });
  } catch (err) {
    next(err);
  }
}

async function remove(req, res, next) {
  try {
    const data = await homeFeedService.removePin(req.params.id);
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = { list, create, update, remove };
