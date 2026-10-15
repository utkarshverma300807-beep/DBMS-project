const express = require('express');
const cors = require('cors');
const env = require('./config/env');
const authRoutes = require('./routes/auth.routes');
const patientRoutes = require('./routes/patient.routes');
const departmentRoutes = require('./routes/department.routes');
const doctorRoutes = require('./routes/doctor.routes');
const appointmentRoutes = require('./routes/appointment.routes');
const { notFound, errorHandler } = require('./middleware/error.middleware');

const app = express();

app.disable('x-powered-by');
app.use(cors({ origin: env.corsOrigin }));
app.use(express.json({ limit: '1mb' }));

app.get('/health', (req, res) => {
  res.json({ service: 'hospital-management-backend', status: 'ok' });
});

app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/departments', departmentRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/appointments', appointmentRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
