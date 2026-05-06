const Doctor = require('../models/Doctor');

// @route GET /api/doctors
const getDoctors = async (req, res) => {
    try {
        const doctors = await Doctor.find({});
        res.json(doctors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route GET /api/doctors/available-now
const getAvailableNowDoctors = async (req, res) => {
    try {
        const doctors = await Doctor.find({ availableNow: true });
        res.json(doctors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route GET /api/doctors/by-specialization
const getDoctorsBySpecialization = async (req, res) => {
    try {
        const { specialization } = req.query;
        let query = {};
        if (specialization) {
            query.specialization = specialization;
        }
        const doctors = await Doctor.find(query);
        res.json(doctors);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route PATCH /api/doctors/:id/availability
// Doctor toggles their own availableNow flag
const toggleAvailability = async (req, res) => {
    try {
        const { id } = req.params;

        const doctor = await Doctor.findById(id);
        if (!doctor) {
            return res.status(404).json({ message: 'Doctor not found' });
        }

        doctor.availableNow = !doctor.availableNow;
        await doctor.save();

        res.json({
            availableNow: doctor.availableNow,
            message: doctor.availableNow
                ? 'You are now available for online consultations'
                : 'You are now offline — patients cannot book online consults'
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { getDoctors, getAvailableNowDoctors, getDoctorsBySpecialization, toggleAvailability };
