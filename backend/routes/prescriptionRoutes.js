const express = require('express');
const router = express.Router();
const { createPrescription, getPatientPrescriptions, getDoctorConsultations } = require('../controllers/prescriptionController');
const { protect, protectDoctor } = require('../middleware/authMiddleware');

// Doctor submits prescription after call ends
router.post('/', protectDoctor, createPrescription);

// Patient views their prescriptions
router.get('/patient/:patientId', protect, getPatientPrescriptions);

// Doctor views their consultation queue
router.get('/doctor/:doctorId', protect, getDoctorConsultations);

module.exports = router;
