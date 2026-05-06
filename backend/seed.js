const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const connectDB = require('./config/db');
const Doctor = require('./models/Doctor');
const User = require('./models/User');
const SymptomRule = require('./models/SymptomRule');
const Pharmacy = require('./models/Pharmacy');

dotenv.config();
connectDB();

const doctors = [
    {
        name: 'Dr. Ramesh Sharma',
        specialization: 'Cardiologist',
        availableDates: [
            { date: '2026-04-12', slots: ['10:00 AM', '11:00 AM', '02:00 PM'] },
            { date: '2026-04-13', slots: ['10:00 AM', '01:00 PM'] }
        ],
        availableNow: true,
        rating: 4.8,
        maxDailyConsultations: 10
    },
    {
        name: 'Dr. Priya Patel',
        specialization: 'General Physician',
        availableDates: [
            { date: '2026-04-12', slots: ['09:00 AM', '12:00 PM'] },
            { date: '2026-04-14', slots: ['02:00 PM', '04:00 PM'] }
        ],
        availableNow: true,
        rating: 4.6,
        maxDailyConsultations: 12
    },
    {
        name: 'Dr. Amit Singh',
        specialization: 'Pulmonologist',
        availableDates: [
            { date: '2026-04-12', slots: ['11:00 AM', '03:00 PM'] }
        ],
        availableNow: true,
        rating: 4.5,
        maxDailyConsultations: 8
    },
    {
        name: 'Dr. Neha Gupta',
        specialization: 'Dermatologist',
        availableDates: [
            { date: '2026-04-13', slots: ['10:00 AM', '11:30 AM'] }
        ],
        availableNow: true,
        rating: 4.7,
        maxDailyConsultations: 10
    },
    {
        name: 'Dr. Suresh Kumar',
        specialization: 'Pediatrician',
        availableDates: [
            { date: '2026-04-12', slots: ['09:00 AM', '10:00 AM', '11:00 AM'] }
        ],
        availableNow: false,
        rating: 4.9,
        maxDailyConsultations: 15
    }
];

const symptomRules = [
    {
        symptoms: ['chest pain', 'palpitations', 'breathlessness'],
        condition: 'Possible Cardiac Issue',
        specialization: 'Cardiologist',
        severity: 'high'
    },
    {
        symptoms: ['chest pain', 'dizziness'],
        condition: 'Cardiac / Blood Pressure Issue',
        specialization: 'Cardiologist',
        severity: 'high'
    },
    {
        symptoms: ['cough', 'fever', 'headache', 'fatigue'],
        condition: 'Viral Infection / Flu',
        specialization: 'General Physician',
        severity: 'medium'
    },
    {
        symptoms: ['fever', 'sore throat', 'runny nose'],
        condition: 'Upper Respiratory Infection',
        specialization: 'General Physician',
        severity: 'low'
    },
    {
        symptoms: ['breathlessness', 'wheezing', 'shortness of breath'],
        condition: 'Asthma / Respiratory Issue',
        specialization: 'Pulmonologist',
        severity: 'high'
    },
    {
        symptoms: ['skin rash', 'itching', 'hives'],
        condition: 'Allergic Reaction / Skin Infection',
        specialization: 'Dermatologist',
        severity: 'low'
    },
    {
        symptoms: ['child fever', 'crying constantly', 'loss of appetite'],
        condition: 'Pediatric Infection',
        specialization: 'Pediatrician',
        severity: 'medium'
    },
    {
        symptoms: ['joint pain', 'swollen joints', 'back pain'],
        condition: 'Musculoskeletal / Arthritis',
        specialization: 'General Physician',
        severity: 'medium'
    },
    {
        symptoms: ['nausea', 'vomiting', 'abdominal pain'],
        condition: 'Gastrointestinal Issue',
        specialization: 'General Physician',
        severity: 'medium'
    }
];

const pharmacies = [
    {
        name: 'ABC Pharmacy',
        location: 'Nabha Main Road',
        medicines: ['Paracetamol', 'Crocin', 'Cough Syrup', 'Ibuprofen', 'Aspirin', 'Amlodipine'],
        latitude: 30.3752, longitude: 76.1485
    },
    {
        name: 'HealthPlus Pharmacy',
        location: 'Bus Stand Area',
        medicines: ['Ibuprofen', 'Paracetamol', 'Metformin', 'Atorvastatin', 'Azithromycin'],
        latitude: 30.3780, longitude: 76.1450
    },
    {
        name: 'MedCare Chemist',
        location: 'Civil Hospital Road',
        medicines: ['Amoxicillin', 'Cetirizine', 'Pantoprazole', 'Crocin', 'Dolo 650'],
        latitude: 30.3810, longitude: 76.1500
    }
];

const importData = async () => {
    try {
        // Clear existing data
        await Doctor.deleteMany();
        await SymptomRule.deleteMany();
        await Pharmacy.collection.drop().catch(() => {});
        // Remove only doctor users, keep patients
        await User.deleteMany({ role: 'doctor' });

        // Seed doctors
        const insertedDoctors = await Doctor.insertMany(doctors);
        console.log(`✓ ${insertedDoctors.length} doctors seeded`);

        // Seed symptom rules
        await SymptomRule.insertMany(symptomRules);
        console.log(`✓ ${symptomRules.length} symptom rules seeded`);

        // Seed pharmacies
        await Pharmacy.insertMany(pharmacies);
        console.log(`✓ ${pharmacies.length} pharmacies seeded`);

        // Seed doctor user accounts (one User per Doctor for login)
        const salt = await bcrypt.genSalt(10);
        const password = await bcrypt.hash('doctor123', salt);

        const doctorEmails = [
            'dr.sharma@clinic.com',
            'dr.patel@clinic.com',
            'dr.singh@clinic.com',
            'dr.gupta@clinic.com',
            'dr.kumar@clinic.com'
        ];

        for (let i = 0; i < insertedDoctors.length; i++) {
            const doc = insertedDoctors[i];
            await User.create({
                patientId: 'DID' + Math.floor(100000 + Math.random() * 900000),
                name: doc.name,
                email: doctorEmails[i],
                password,
                role: 'doctor',
                linkedDoctorId: doc._id,
                age: 0,
                gender: 'N/A'
            });
        }
        console.log(`✓ ${insertedDoctors.length} doctor accounts created`);
        console.log('\n🩺 Doctor login credentials:');
        doctorEmails.forEach((email, i) => {
            console.log(`   ${doctors[i].name.padEnd(22)} → ${email}  /  password: doctor123`);
        });

        console.log('\n✅ All data seeded successfully!\n');
        process.exit();
    } catch (error) {
        console.error(`❌ Error: ${error.message}`);
        process.exit(1);
    }
};

importData();
