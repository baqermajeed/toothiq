const express = require('express');
const appVersionController = require('../controllers/appVersionController');

const router = express.Router();

router.get('/check', appVersionController.checkVersion);
router.get('/check-v2', appVersionController.checkVersionV2);

module.exports = router;
