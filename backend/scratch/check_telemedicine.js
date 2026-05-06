const mongoose = require('mongoose');
const User = require('../models/User');
const Doctor = require('../models/Doctor');
const dotenv = require('dotenv');

dotenv.config();

const checkTelemedicine = async () => {
    try {
        await mongoose.connect('mongodb://localhost:27017/telemedicine');
        const userCount = await User.countDocuments();
        const doctorCount = await Doctor.countDocuments();
        console.log(`Telemedicine DB - Users: ${userCount}, Doctors: ${doctorCount}`);
        
        const shivani = await User.findOne({ email: 'shivanivanamala@gmail.com' });
        console.log('Shivani in Telemedicine:', !!shivani);
        
        process.exit();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

checkTelemedicine();
