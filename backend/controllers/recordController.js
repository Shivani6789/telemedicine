const MedicalRecord = require('../models/MedicalRecord');
const { encryptAES, decryptAES } = require('../utils/encryption');

// @route GET /api/records/:patientId?search=...&date=YYYY-MM-DD&category=...
const getRecords = async (req, res) => {
    try {
        const patientId = req.params.patientId;

        // Allow patient to see own records; allow doctors to see any patient records
        if (req.user.id !== patientId && req.user.role !== 'doctor') {
            return res.status(403).json({ message: 'Forbidden' });
        }

        const { search, date, category } = req.query;

        const query = { patientId };
        if (category) query.category = category;

        const records = await MedicalRecord.find(query).sort({ dateTime: -1 });

        // Decrypt and enrich each record
        let decryptedRecords = records.map(record => {
            let data = {};
            try {
                data = decryptAES(record.encryptedData);
            } catch (e) {
                console.error('Decryption failed for record', record._id);
            }
            return {
                _id: record._id,
                patientId: record.patientId,
                doctorName: record.doctorName,
                doctorId: record.doctorId,
                consultationType: record.consultationType,
                category: record.category || (record.consultationType === 'online' ? 'Online Consultation' : 'Offline Visit'),
                dateTime: record.dateTime,
                linkedPrescriptionId: record.linkedPrescriptionId,
                ...data
            };
        });

        // In-memory search by doctor name or diagnosis keyword
        if (search) {
            const s = search.toLowerCase();
            decryptedRecords = decryptedRecords.filter(r =>
                r.doctorName?.toLowerCase().includes(s) ||
                r.diagnosis?.toLowerCase().includes(s) ||
                r.condition?.toLowerCase().includes(s)
            );
        }

        // In-memory filter by date (YYYY-MM-DD)
        if (date) {
            decryptedRecords = decryptedRecords.filter(r =>
                r.dateTime && new Date(r.dateTime).toISOString().startsWith(date)
            );
        }

        res.json(decryptedRecords);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @route POST /api/records/add
const addRecord = async (req, res) => {
    try {
        const { doctorName, consultationType, category, details } = req.body;
        const patientId = req.user.id;

        const encryptedData = encryptAES(details);

        const record = await MedicalRecord.create({
            patientId,
            doctorName,
            consultationType,
            category: category || (consultationType === 'online' ? 'Online Consultation' : 'Offline Visit'),
            encryptedData
        });

        res.status(201).json(record);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { getRecords, addRecord };

