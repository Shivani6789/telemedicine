const mongoose = require('mongoose');
const User = require('../models/User');
const dotenv = require('dotenv');

dotenv.config();

const checkUser = async () => {
    try {
        const dbs = ['test', 'telemedicine'];
        for (const dbName of dbs) {
            console.log(`Checking database: ${dbName}`);
            await mongoose.disconnect();
            await mongoose.connect(`mongodb://localhost:27017/${dbName}`);
            const user = await User.findOne({ email: 'shivanivanamala@gmail.com' });
            if (user) {
                console.log(`User found in ${dbName}:`);
                console.log(JSON.stringify(user, null, 2));
                process.exit();
            } else {
                console.log(`User not found in ${dbName}.`);
            }
        }
        process.exit();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

checkUser();
