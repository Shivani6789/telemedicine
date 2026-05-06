const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// JWT now encodes both id and role for role-based middleware
const generateToken = (id, role) => {
    return jwt.sign({ id, role }, process.env.JWT_SECRET || 'fallback_secret', {
        expiresIn: '30d',
    });
};

const registerUser = async (req, res) => {
    try {
        const { name, email, password, phone, age, gender, role, linkedDoctorId } = req.body;

        const userExists = await User.findOne({ email });
        if (userExists) {
            return res.status(400).json({ message: 'User already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // DID prefix for doctors, PID for patients
        const prefix = (role === 'doctor') ? 'DID' : 'PID';
        const patientId = prefix + Math.floor(100000 + Math.random() * 900000);

        const userData = {
            patientId,
            name,
            email,
            password: hashedPassword,
            phone,
            age: age || 0,
            gender: gender || 'N/A',
            role: role || 'patient',
        };
        if (linkedDoctorId) userData.linkedDoctorId = linkedDoctorId;

        const user = await User.create(userData);

        if (user) {
            res.status(201).json({
                _id: user._id,
                patientId: user.patientId,
                name: user.name,
                email: user.email,
                role: user.role,
                linkedDoctorId: user.linkedDoctorId,
                token: generateToken(user._id, user.role),
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ email });

        if (user && (await bcrypt.compare(password, user.password))) {
            res.json({
                _id: user._id,
                patientId: user.patientId,
                name: user.name,
                email: user.email,
                role: user.role,
                linkedDoctorId: user.linkedDoctorId,
                token: generateToken(user._id, user.role),
            });
        } else {
            res.status(401).json({ message: 'Invalid email or password' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = { registerUser, loginUser };

