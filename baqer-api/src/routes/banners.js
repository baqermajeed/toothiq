const express = require('express');
const bannerController = require('../controllers/bannerController');
const { optionalAuthenticate } = require('../middlewares/auth');

const router = express.Router();

router.get('/', optionalAuthenticate, bannerController.list);

module.exports = router;
