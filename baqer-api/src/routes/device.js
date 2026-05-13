const express = require('express');
const deviceController = require('../controllers/deviceController');

const router = express.Router();

// GET أو POST - يحدد نظام التشغيل ويحوّل لمتجر التطبيق (الرابط: https://my-domain/qareep)
router.get('/', deviceController.getPlatform);
router.post('/', deviceController.getPlatform);

module.exports = router;
