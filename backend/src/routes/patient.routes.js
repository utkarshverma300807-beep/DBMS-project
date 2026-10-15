const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const {
  createPatient,
  getPatientByPhone,
  updatePatient
} = require('../controllers/patient.controller');

const router = express.Router();

// Patient registration/lookup is used by the kiosk flow. Staff can update records.
router.post('/', createPatient);
router.get('/phone/:phone', getPatientByPhone);
router.put('/:id', authenticate, requireRole('ADMIN', 'RECEPTIONIST'), updatePatient);

module.exports = router;
