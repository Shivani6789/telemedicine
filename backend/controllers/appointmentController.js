const Appointment = require('../models/Appointment');
const Doctor = require('../models/Doctor');
const MedicalRecord = require('../models/MedicalRecord');
const { encryptAES } = require('../utils/encryption');

// @route POST /api/appointments/book  (Offline visit)
const bookOfflineAppointment = async (req, res) => {
    try {
        const { doctorId, date, slot, patientName, patientAge, patientGender } = req.body;
        const patientId = req.user.id;

        // Double-booking prevention
        const existingAppointment = await Appointment.findOne({ doctorId, date, slot, type: 'offline' });
        if (existingAppointment) {
            return res.status(400).json({ message: 'Slot already booked. Please choose another time.' });
        }

        const doctor = await Doctor.findById(doctorId);
        if (!doctor) return res.status(404).json({ message: 'Doctor not found' });

        const appointment = await Appointment.create({
            patientId,
            doctorId,
            patientName,
            patientAge,
            patientGender,
            type: 'offline',
            date,
            slot,
            status: 'pending'
        });

        // Auto-create Medical Record for this booking
        const details = { bookedSlot: slot, date, status: 'pending', patientName, patientAge, patientGender };
        const encryptedData = encryptAES(details);
        await MedicalRecord.create({
            patientId,
            doctorName: doctor.name,
            doctorId: doctor._id,
            consultationType: 'offline',
            category: 'Offline Visit',
            encryptedData
        });

        res.status(201).json(appointment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route POST /api/appointments/online-consult
const bookOnlineConsultation = async (req, res) => {
    try {
        const { doctorId, patientName, patientAge, patientGender } = req.body;
        const patientId = req.user.id;

        const doctor = await Doctor.findById(doctorId);
        if (!doctor) return res.status(404).json({ message: 'Doctor not found' });
        if (!doctor.availableNow) {
            return res.status(400).json({ message: 'Doctor is not available for online consultation right now.' });
        }

        // Feature 2: Doctor Scalability & Queue Limits
        // Prevent overload by limiting the number of ACTIVE/PENDING patients waiting in the queue
        const activeQueueCount = await Appointment.countDocuments({
            doctorId,
            type: 'online',
            status: 'pending'
        });

        if (activeQueueCount >= 5) {
            return res.status(429).json({
                message: `Dr. ${doctor.name}'s active queue is currently full. Please wait a few minutes or try another doctor.`
            });
        }

        const appointment = await Appointment.create({
            patientId,
            doctorId,
            patientName,
            patientAge,
            patientGender,
            type: 'online',
            status: 'pending'   // prescription will be linked by doctor after call
        });

        // Increment doctor's daily consultation count
        await Doctor.findByIdAndUpdate(doctorId, { $inc: { todayConsultationCount: 1 } });

        // Create initial Medical Record — prescription will be linked later
        const details = { status: 'pending', patientName, patientAge, patientGender };
        const encryptedData = encryptAES(details);
        await MedicalRecord.create({
            patientId,
            doctorName: doctor.name,
            doctorId: doctor._id,
            consultationType: 'online',
            category: 'Online Consultation',
            encryptedData
        });

        res.status(201).json(appointment);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route GET /api/appointments/doctor/:doctorId
// Doctor Dashboard: list of pending online appointments
const getDoctorAppointments = async (req, res) => {
    try {
        const { doctorId } = req.params;
        const appointments = await Appointment.find({
            doctorId,
            type: 'online',
            status: { $in: ['pending', 'completed'] }
        }).sort({ createdAt: -1 });
        res.json(appointments);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { bookOfflineAppointment, bookOnlineConsultation, getDoctorAppointments };

