const homeFeedService = require('../services/homeFeedService');

function parsePaging(query = {}) {
  return { page: query.page, limit: query.limit };
}

async function offers(req, res, next) {
  try {
    const data = await homeFeedService.listOffers(parsePaging(req.query));
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function bestSellers(req, res, next) {
  try {
    const data = await homeFeedService.listBestSellers(parsePaging(req.query));
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function forYou(req, res, next) {
  try {
    const data = await homeFeedService.listForYou({
      ...parsePaging(req.query),
      userId: req.userId,
    });
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function newest(req, res, next) {
  try {
    const data = await homeFeedService.listNew(parsePaging(req.query));
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

async function topRated(req, res, next) {
  try {
    const data = await homeFeedService.listTopRated(parsePaging(req.query));
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  offers,
  bestSellers,
  forYou,
  newest,
  topRated,
};
