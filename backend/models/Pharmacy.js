const mongoose = require('mongoose');

const pharmacySchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  location: {
    type: String,
    required: true,
  },
  medicines: {
    type: [String],
    default: [],
  },
  latitude: {
    type: Number,
  },
  longitude: {
    type: Number,
  }
}, {
  timestamps: true,
});

// Create a text index on medicines for faster search (optional but good practice)
pharmacySchema.index({ medicines: 'text' });

module.exports = mongoose.model('Pharmacy', pharmacySchema);
