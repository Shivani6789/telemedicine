const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

const listDbs = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/');
        const admin = mongoose.connection.useDb('admin').db.admin();
        const dbs = await admin.listDatabases();
        console.log(JSON.stringify(dbs, null, 2));
        process.exit();
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
};

listDbs();
