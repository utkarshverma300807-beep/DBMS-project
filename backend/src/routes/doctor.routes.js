const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { listDoctors, createDoctor } = require('../controllers/doctor.controller');

const router = express.Router();

router.get('/', listDoctors);
router.post('/', authenticate, requireRole('ADMIN'), createDoctor);

module.exports = router;
