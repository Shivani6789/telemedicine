const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  doctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor', required: true },
  patientName: { type: String, required: true },
  patientAge: { type: Number, required: true },
  patientGender: { type: String, required: true },
  type: { type: String, enum: ['online', 'offline'], required: true },
  date: { type: String }, // For offline
  slot: { type: String }, // For offline
  status: { type: String, enum: ['pending', 'completed', 'cancelled'], default: 'pending' },
  prescription: { type: String } // Stored encrypted potentially or plain text depending on records
}, { timestamps: true });

module.exports = mongoose.model('Appointment', appointmentSchema);
