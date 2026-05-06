const mongoose = require('mongoose');

const medicalRecordSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  doctorName: { type: String, required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' },
  consultationType: { type: String, enum: ['online', 'offline'], required: true },
  category: {
    type: String,
    enum: ['Online Consultation', 'Offline Visit', 'Prescription'],
    default: 'Online Consultation'
  },
  dateTime: { type: Date, default: Date.now },
  encryptedData: { type: String, required: true }, // Encrypted JSON: { prescription, medicines, diagnosis, bookedSlot, status, etc }
  linkedPrescriptionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Prescription' }
}, { timestamps: true });

module.exports = mongoose.model('MedicalRecord', medicalRecordSchema);
