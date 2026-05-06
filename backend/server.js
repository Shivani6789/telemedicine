const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/db');

dotenv.config();

connectDB();

const app = express();

// Allow Flutter web dev server (any localhost port) and Android emulator
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, native flutter, curl, etc.)
    if (!origin) return callback(null, true);
    
    // Allow localhost, 127.0.0.1, and the current LAN IP
    if (/^http:\/\/(localhost|127\.0\.0\.1|192\.168\.0\.216|172\.20\.10\.2|192\.168\.1\.6)(:\d+)?$/.test(origin)) {
      return callback(null, true);
    }
    
    callback(new Error(`CORS blocked: ${origin}`));
  },
  credentials: true,
}));
app.use(express.json());

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/doctors', require('./routes/doctorRoutes'));
app.use('/api/appointments', require('./routes/appointmentRoutes'));
app.use('/api/symptoms', require('./routes/symptomRoutes'));
app.use('/api/records', require('./routes/recordRoutes'));
app.use('/api/pharmacies', require('./routes/pharmacyRoutes'));
app.use('/api/prescriptions', require('./routes/prescriptionRoutes'));

const http = require('http');
const { Server } = require("socket.io");

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// ──────────────────────────────────────────────
//  WebRTC Signaling Events
//  Room = appointmentId (shared by patient & doctor)
// ──────────────────────────────────────────────
io.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}`);

  // Both patient and doctor call join-room with the appointmentId
  socket.on('join-room', (roomId) => {
    socket.join(roomId);
    const room = io.sockets.adapter.rooms.get(roomId);
    const numClients = room ? room.size : 0;
    
    console.log(`Socket ${socket.id} joined room ${roomId}. Total clients: ${numClients}`);
    
    // Notify existing participants that a new peer arrived
    // The existing participant (patient) hears this and creates the WebRTC offer
    socket.to(roomId).emit('user-joined', { socketId: socket.id });

    // If another participant is already in the room (e.g. Doctor joined first),
    // notify the joining user so they can initiate the offer if they are the patient.
    if (numClients > 1) {
      socket.emit('user-joined', { socketId: 'existing' });
    }
  });

  // Patient → Server → Doctor
  socket.on('offer', (data) => {
    socket.to(data.roomId).emit('offer', data);
  });

  // Doctor → Server → Patient
  socket.on('answer', (data) => {
    socket.to(data.roomId).emit('answer', data);
  });

  // Both sides exchange ICE candidates
  socket.on('ice-candidate', (data) => {
    socket.to(data.roomId).emit('ice-candidate', data);
  });

  // Either side can end the call
  socket.on('end-call', (roomId) => {
    io.to(roomId).emit('call-ended');
  });

  socket.on('leave-call', (roomId) => {
    io.to(roomId).emit('call-ended');
    socket.leave(roomId);
  });

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));

process.on('unhandledRejection', (err) => {
  console.log('UNHANDLED REJECTION! 💥 Shutting down...');
  console.log(err.name, err.message);
  server.close(() => {
    process.exit(1);
  });
});

process.on('uncaughtException', (err) => {
  console.log('UNCAUGHT EXCEPTION! 💥 Shutting down...');
  console.log(err.name, err.message);
  process.exit(1);
});

