const express = require('express');
const governoratesController = require('../controllers/governoratesController');

const router = express.Router();

router.get('/', governoratesController.list);

module.exports = router;
