const express = require('express');
const productController = require('../controllers/productController');
const { optionalAuthenticate } = require('../middlewares/auth');

const router = express.Router();

router.get('/', optionalAuthenticate, productController.listAll);
router.get('/random-multi-shops', optionalAuthenticate, productController.listRandomMultiShops);
router.get('/search', optionalAuthenticate, productController.search);
router.post('/search', optionalAuthenticate, productController.searchPost);

module.exports = router;
