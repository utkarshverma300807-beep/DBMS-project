const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const {
  listDepartments,
  createDepartment,
  updateDepartment
} = require('../controllers/department.controller');

const router = express.Router();

router.get('/', listDepartments);
router.post('/', authenticate, requireRole('ADMIN'), createDepartment);
router.put('/:id', authenticate, requireRole('ADMIN'), updateDepartment);

module.exports = router;
