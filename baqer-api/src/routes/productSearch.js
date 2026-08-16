const express = require('express');
const productController = require('../controllers/productController');
const homeFeedController = require('../controllers/homeFeedController');
const { optionalAuthenticate } = require('../middlewares/auth');

const router = express.Router();

router.get('/all', optionalAuthenticate, homeFeedController.all);
router.get('/offers', optionalAuthenticate, homeFeedController.offers);
router.get('/best-sellers', optionalAuthenticate, homeFeedController.bestSellers);
router.get('/for-you', optionalAuthenticate, homeFeedController.forYou);
router.get('/new', optionalAuthenticate, homeFeedController.newest);
router.get('/', optionalAuthenticate, productController.listAll);
router.get('/random-multi-shops', optionalAuthenticate, productController.listRandomMultiShops);
router.get('/search', optionalAuthenticate, productController.search);
router.post('/search', optionalAuthenticate, productController.searchPost);

module.exports = router;
