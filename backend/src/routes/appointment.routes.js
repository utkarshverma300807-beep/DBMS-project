const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const {
  bookAppointment,
  getAppointment,
  listAppointments,
  updateStatus,
  cancelAppointment,
  getQueue
} = require('../controllers/appointment.controller');

const router = express.Router();

router.post('/', bookAppointment);
router.get('/', authenticate, requireRole('ADMIN', 'RECEPTIONIST', 'DOCTOR'), listAppointments);
router.get('/queue/:departmentId', getQueue);
router.get('/:id', getAppointment);
router.put('/:id/status', authenticate, requireRole('ADMIN', 'RECEPTIONIST', 'DOCTOR'), updateStatus);
router.post('/:id/cancel', authenticate, requireRole('ADMIN', 'RECEPTIONIST', 'DOCTOR'), cancelAppointment);

module.exports = router;
