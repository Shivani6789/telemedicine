const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  name: { type: String, required: true },
  specialization: { type: String, required: true },
  availableDates: [{
    date: { type: String, required: true }, // YYYY-MM-DD
    slots: [{ type: String, required: true }] // HH:MM AM/PM
  }],
  availableNow: { type: Boolean, default: false }, // For online consulting
  rating: { type: Number, default: 4.0, min: 1, max: 5 },
  maxDailyConsultations: { type: Number, default: 10 },
  todayConsultationCount: { type: Number, default: 0 }
}, { timestamps: true });

module.exports = mongoose.model('Doctor', doctorSchema);
