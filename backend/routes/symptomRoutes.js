const express = require('express');
const router = express.Router();
const { analyzeSymptoms } = require('../controllers/symptomController');
const { protect } = require('../middleware/authMiddleware');

router.post('/analyze', protect, analyzeSymptoms);

module.exports = router;
