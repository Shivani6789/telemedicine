const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  patientId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String },
  age: { type: Number, default: 0 },
  gender: { type: String, default: 'N/A' },
  role: { type: String, enum: ['patient', 'doctor'], default: 'patient' },
  linkedDoctorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor' }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
