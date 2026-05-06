const mongoose = require('mongoose');

const symptomRuleSchema = new mongoose.Schema({
  symptoms: [{ type: String, required: true }],
  condition: { type: String, required: true },
  specialization: { type: String, required: true },
  severity: { type: String, enum: ['low', 'medium', 'high'], default: 'medium' }
}, { timestamps: true });

module.exports = mongoose.model('SymptomRule', symptomRuleSchema);
