const express = require('express');
const router = express.Router();
const { getRecords, addRecord } = require('../controllers/recordController');
const { protect } = require('../middleware/authMiddleware');

// GET /api/records/:patientId?search=&date=&category=
router.get('/:patientId', protect, getRecords);
router.post('/add', protect, addRecord);

module.exports = router;

