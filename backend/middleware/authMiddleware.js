const jwt = require('jsonwebtoken');

const protect = (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            // Decoded now contains: { id, role }
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback_secret');
            req.user = decoded;
            next();
        } catch (error) {
            console.error(error);
            res.status(401).json({ message: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        res.status(401).json({ message: 'Not authorized, no token' });
    }
};

// Doctor-only middleware — chains protect then checks role
const protectDoctor = (req, res, next) => {
    protect(req, res, () => {
        if (req.user && req.user.role === 'doctor') {
            next();
        } else {
            res.status(403).json({ message: 'Access denied: doctor role required' });
        }
    });
};

module.exports = { protect, protectDoctor };

