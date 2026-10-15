const { db } = require('../config/database');
const { doctors, doctorDepartments, departments } = require('../db/schema');
const { eq, and, asc } = require('drizzle-orm');

async function listDoctors(req, res, next) {
  try {
    const filters = [eq(doctors.active, true), eq(departments.active, true)];
    if (req.query.department_id) filters.push(eq(doctorDepartments.departmentId, Number(req.query.department_id)));

    const rows = await db.select({
      doctorId: doctors.doctorId,
      firstName: doctors.firstName,
      lastName: doctors.lastName,
      specialization: doctors.specialization,
      defaultRoomNumber: doctors.defaultRoomNumber,
      departmentId: doctorDepartments.departmentId,
      departmentName: departments.departmentName
    }).from(doctors)
      .innerJoin(doctorDepartments, eq(doctorDepartments.doctorId, doctors.doctorId))
      .innerJoin(departments, eq(departments.departmentId, doctorDepartments.departmentId))
      .where(and(...filters))
      .orderBy(asc(doctors.lastName), asc(doctors.firstName));
    return res.json(rows);
  } catch (error) {
    return next(error);
  }
}

async function createDoctor(req, res, next) {
  try {
    const {
      first_name: firstName, last_name: lastName = null, phone_number: phoneNumber = null,
      email = null, specialization, license_number: licenseNumber,
      default_room_number: room = null, department_ids: departmentIds = []
    } = req.body;

    if (!firstName || !specialization || !licenseNumber || !Array.isArray(departmentIds) || departmentIds.length === 0) {
      return res.status(400).json({ error: 'first_name, specialization, license_number, and department_ids are required.' });
    }

    const doctor = await db.transaction(async (tx) => {
      const [created] = await tx.insert(doctors).values({
        firstName, lastName, phoneNumber, email, specialization,
        licenseNumber, defaultRoomNumber: room
      }).returning();
      await tx.insert(doctorDepartments).values(departmentIds.map((departmentId, index) => ({
        doctorId: created.doctorId,
        departmentId: Number(departmentId),
        isPrimaryDepartment: index === 0
      })));
      return created;
    });
    return res.status(201).json(doctor);
  } catch (error) {
    return next(error);
  }
}

module.exports = { listDoctors, createDoctor };
