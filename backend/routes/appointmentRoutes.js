const express = require('express');
const router = express.Router();
const { bookOfflineAppointment, bookOnlineConsultation, getDoctorAppointments } = require('../controllers/appointmentController');
const { protect } = require('../middleware/authMiddleware');

router.post('/book', protect, bookOfflineAppointment);
router.post('/online-consult', protect, bookOnlineConsultation);
router.get('/doctor/:doctorId', protect, getDoctorAppointments);

module.exports = router;

