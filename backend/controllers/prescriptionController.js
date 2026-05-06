const Prescription = require('../models/Prescription');
const MedicalRecord = require('../models/MedicalRecord');
const Appointment = require('../models/Appointment');
const User = require('../models/User');
const { encryptAES, decryptAES } = require('../utils/encryption');

// @route POST /api/prescriptions  (Doctor only)
// Called by doctor after ending a video call — auto-links to Medical Records
const createPrescription = async (req, res) => {
    try {
        const { patientId, appointmentId, diagnosis, medicines, notes } = req.body;

        // Look up the doctor User record to grab name + linkedDoctorId
        const doctorUser = await User.findById(req.user.id);
        const doctorId = doctorUser?.linkedDoctorId;
        const doctorName = doctorUser?.name || 'Doctor';

        // Feature 5: Data Security
        // Encrypt the sensitive medical data before saving to the Prescription database
        const sensitivePayload = {
            diagnosis,
            medicines,
            notes: notes || ''
        };
        const prescriptionEncryptedData = encryptAES(sensitivePayload);

        const prescription = await Prescription.create({
            patientId,
            doctorId,
            doctorName,
            appointmentId: appointmentId || undefined,
            encryptedData: prescriptionEncryptedData
        });

        // Mark the appointment as completed
        if (appointmentId) {
            await Appointment.findByIdAndUpdate(appointmentId, { status: 'completed' });
        }

        // Build a human-readable prescription summary for the encrypted record
        const medicineText = medicines
            .map(m => {
                const timings = [];
                if (m.morning) timings.push('Morn');
                if (m.afternoon) timings.push('Aft');
                if (m.evening) timings.push('Eve');
                const timingStr = timings.length > 0 ? `(${timings.join('-')})` : '';
                return `${m.name} ${m.dosage} ${timingStr} for ${m.duration}`;
            })
            .join('; ');

        const details = {
            diagnosis,
            medicines,
            notes: notes || '',
            prescription: medicineText,   // for pharmacy search compatibility
            status: 'completed'
        };

        const encryptedData = encryptAES(details);

        // Auto-create Medical Record categorised as Prescription
        const record = await MedicalRecord.create({
            patientId,
            doctorName,
            doctorId,
            consultationType: 'online',
            category: 'Prescription',
            encryptedData,
            linkedPrescriptionId: prescription._id
        });

        res.status(201).json({ prescription, record });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route GET /api/prescriptions/patient/:patientId
const getPatientPrescriptions = async (req, res) => {
    try {
        const { patientId } = req.params;
        // Patients can only view their own; doctors can view any
        if (req.user.id !== patientId && req.user.role !== 'doctor') {
            return res.status(403).json({ message: 'Forbidden' });
        }
        const prescriptions = await Prescription.find({ patientId }).sort({ dateTime: -1 }).lean();

        // Feature 5: Data Security — decrypt on the fly
        const decryptedPrescriptions = prescriptions.map(p => {
            if (p.encryptedData) {
                try {
                    const dec = decryptAES(p.encryptedData);
                    return { ...p, diagnosis: dec.diagnosis, medicines: dec.medicines, notes: dec.notes };
                } catch (e) {
                    console.error("Prescription decryption failed", p._id);
                    return p;
                }
            }
            return p;
        });

        res.json(decryptedPrescriptions);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route GET /api/prescriptions/doctor/:doctorId
// Doctor-facing: list pending online appointments for this doctor (consultation queue)
const getDoctorConsultations = async (req, res) => {
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

module.exports = { createPrescription, getPatientPrescriptions, getDoctorConsultations };
