const express = require('express');
const catalogController = require('../controllers/catalogController');
const { optionalAuthenticate } = require('../middlewares/auth');

const router = express.Router({ mergeParams: true });

router.get('/', optionalAuthenticate, catalogController.getShopCatalog);

module.exports = router;
