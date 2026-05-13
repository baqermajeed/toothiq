const express = require('express');
const publicAppSettingsController = require('../controllers/publicAppSettingsController');

const router = express.Router();

router.get('/app-settings', publicAppSettingsController.getAppSettings);

module.exports = router;
