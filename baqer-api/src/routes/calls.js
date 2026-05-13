const express = require('express');
const callsController = require('../controllers/callsController');
const { authenticate } = require('../middlewares/auth');

const router = express.Router();

router.get('/config', authenticate, callsController.getConfig);

module.exports = router;
