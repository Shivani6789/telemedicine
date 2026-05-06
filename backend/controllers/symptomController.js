const SymptomRule = require('../models/SymptomRule');
const Doctor = require('../models/Doctor');

// @route POST /api/symptoms/analyze
const analyzeSymptoms = async (req, res) => {
    try {
        const { symptoms } = req.body;
        if (!symptoms || symptoms.length === 0) {
            return res.status(400).json({ message: 'No symptoms provided' });
        }

        // Find all rules that match any given symptom
        const rules = await SymptomRule.find({ symptoms: { $in: symptoms } });

        if (rules.length === 0) {
            const fallbackDoctors = await Doctor.find({ specialization: 'General Physician' }).limit(3);
            return res.json({
                condition: 'Unknown',
                severity: 'low',
                specialization: 'General Physician',
                message: 'No exact matches. Please consult a General Physician.',
                recommendations: fallbackDoctors.map(d => ({
                    doctor: d,
                    score: d.rating + (d.availableNow ? 5 : 0),
                    specialization: 'General Physician',
                    explanation: 'Recommended General Physician for general consultation'
                }))
            });
        }

        // Score each rule by number of overlapping symptoms
        const scoredRules = rules.map(rule => {
            const matchedSymptoms = rule.symptoms.filter(s => symptoms.includes(s));
            return { rule, matchCount: matchedSymptoms.length, matchedSymptoms };
        }).sort((a, b) => b.matchCount - a.matchCount);

        const primaryMatch = scoredRules[0];

        // Collect unique specializations (best-scoring per spec)
        const specMap = {};
        for (const { rule, matchCount, matchedSymptoms } of scoredRules) {
            if (!specMap[rule.specialization]) {
                specMap[rule.specialization] = { matchCount, matchedSymptoms, condition: rule.condition };
            }
        }

        // For each specialization, fetch and score doctors
        let allRecommendations = [];
        for (const [spec, info] of Object.entries(specMap)) {
            const doctors = await Doctor.find({ specialization: spec });
            for (const doc of doctors) {
                // Feature 1: Intelligent Doctor Recommendation Scoring
                // 50% = Specialization Match (based on symptom matchCount ratio)
                // 30% = Availability
                // 20% = Dynamic Weight / Rating

                // Normalize match ratio (max cap at 1)
                const matchRatio = Math.min(info.matchCount / symptoms.length, 1.0);
                const specScore = matchRatio * 50; // max 50 points

                const availScore = doc.availableNow ? 30 : 0; // 30 points if online

                // 20% dynamic/rating weight: baseline rating (out of 5 * 2) + randomized active factor (0 to 10 points)
                const baseRatingScore = (doc.rating || 4.0) * 2; // max 10
                const randomFactor = Math.floor(Math.random() * 11); // 0 to 10
                const dynamicScore = baseRatingScore + randomFactor; // max 20

                const totalScore = Math.floor(specScore + availScore + dynamicScore);
                
                const symptomList = info.matchedSymptoms.join(', ');
                let explanation = `Recommended ${spec} (Match: ${Math.floor(specScore * 2)}%) due to ${symptomList}.`;
                if (doc.availableNow) {
                    explanation += ` Highly recommended because doctor is currently online and available.`;
                }

                allRecommendations.push({
                    doctor: doc,
                    score: totalScore,
                    specialization: spec,
                    explanation
                });
            }
        }

        // Sort by score descending, return top 3
        allRecommendations.sort((a, b) => b.score - a.score);
        const top3 = allRecommendations.slice(0, 3);

        res.json({
            condition: primaryMatch.rule.condition,
            severity: primaryMatch.rule.severity,
            specialization: primaryMatch.rule.specialization,
            message: `Match found based on: ${primaryMatch.matchedSymptoms.join(', ')}`,
            recommendations: top3
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { analyzeSymptoms };
