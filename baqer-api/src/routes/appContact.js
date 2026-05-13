const express = require('express');
const appContactController = require('../controllers/appContactController');

const router = express.Router();

router.get('/', appContactController.getPublic);

module.exports = router;
