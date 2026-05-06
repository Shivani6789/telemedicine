const mongoose = require('mongoose');

const prescriptionSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' },
  doctorName: { type: String, required: true },
  appointmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Appointment' },
  // Feature 5: Data Security (Visible Implementation)
  // Sensitive medical data is now encrypted before storage
  encryptedData: { type: String, required: true },
  
  // Legacy fields (optional) for backward compatibility
  diagnosis: { type: String },
  medicines: [
    {
      name: { type: String },
      dosage: { type: String },
      duration: { type: String }
    }
  ],
  notes: { type: String, default: '' },
  dateTime: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Prescription', prescriptionSchema);
