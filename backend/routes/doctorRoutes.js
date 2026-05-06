const express = require('express');
const router = express.Router();
const {
    getDoctors,
    getAvailableNowDoctors,
    getDoctorsBySpecialization,
    toggleAvailability
} = require('../controllers/doctorController');
const { protect, protectDoctor } = require('../middleware/authMiddleware');

router.get('/', protect, getDoctors);
router.get('/available-now', protect, getAvailableNowDoctors);
router.get('/by-specialization', protect, getDoctorsBySpecialization);

// Doctor-only: toggle their own online/offline availability
router.patch('/:id/availability', protectDoctor, toggleAvailability);

module.exports = router;
