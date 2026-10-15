const bcrypt = require('bcryptjs');
const { db, closeDatabase } = require('./index');
const { sql } = require('drizzle-orm');
const {
  departments,
  doctors,
  staffUsers,
  patients,
  doctorDepartments,
  doctorSchedules
} = require('./schema');

async function seed() {
  const passwordHash = await bcrypt.hash('password', 10);

  await db.insert(departments).values([
    { departmentId: 1, departmentName: 'General Medicine', departmentCode: 'GEN', location: 'Ground Floor', active: true },
    { departmentId: 2, departmentName: 'Cardiology', departmentCode: 'CAR', location: 'First Floor', active: true },
    { departmentId: 3, departmentName: 'Emergency', departmentCode: 'ER', location: 'Emergency Block', active: true }
  ]).onConflictDoNothing();

  await db.insert(doctors).values([
    { doctorId: 1, firstName: 'Aarav', lastName: 'Sharma', email: 'aarav@hospital.test', specialization: 'General Physician', licenseNumber: 'LIC-GEN-001', defaultRoomNumber: 'G-101' },
    { doctorId: 2, firstName: 'Meera', lastName: 'Nair', email: 'meera@hospital.test', specialization: 'Cardiologist', licenseNumber: 'LIC-CAR-001', defaultRoomNumber: 'C-201' },
    { doctorId: 3, firstName: 'Rohan', lastName: 'Iyer', email: 'rohan@hospital.test', specialization: 'Emergency Physician', licenseNumber: 'LIC-ER-001', defaultRoomNumber: 'E-001' }
  ]).onConflictDoNothing();

  await db.insert(doctorDepartments).values([
    { doctorId: 1, departmentId: 1, isPrimaryDepartment: true },
    { doctorId: 2, departmentId: 2, isPrimaryDepartment: true },
    { doctorId: 3, departmentId: 3, isPrimaryDepartment: true }
  ]).onConflictDoNothing();

  await db.insert(doctorSchedules).values([
    { scheduleId: 1, doctorId: 1, departmentId: 1, dayOfWeek: 1, startTime: '09:00:00', endTime: '13:00:00', maxAppointments: 20 },
    { scheduleId: 2, doctorId: 2, departmentId: 2, dayOfWeek: 2, startTime: '10:00:00', endTime: '14:00:00', maxAppointments: 16 },
    { scheduleId: 3, doctorId: 3, departmentId: 3, dayOfWeek: 1, startTime: '00:00:00', endTime: '23:59:00', maxAppointments: 50 }
  ]).onConflictDoNothing();

  await db.insert(staffUsers).values([
    { userId: 1, username: 'admin', email: 'admin@hospital.test', passwordHash, role: 'ADMIN' },
    { userId: 2, username: 'reception', email: 'reception@hospital.test', passwordHash, role: 'RECEPTIONIST' },
    { userId: 3, username: 'doctor.aarav', email: 'aarav.login@hospital.test', passwordHash, role: 'DOCTOR', doctorId: 1 },
    { userId: 4, username: 'doctor.meera', email: 'meera.login@hospital.test', passwordHash, role: 'DOCTOR', doctorId: 2 },
    { userId: 5, username: 'doctor.rohan', email: 'rohan.login@hospital.test', passwordHash, role: 'DOCTOR', doctorId: 3 }
  ]).onConflictDoNothing();

  await db.insert(patients).values([
    { patientId: 1, phoneNumber: '+91-9111111111', firstName: 'Priya', lastName: 'Shah', gender: 'FEMALE' },
    { patientId: 2, phoneNumber: '+91-9333333333', firstName: 'Vikram', lastName: 'Joshi', gender: 'MALE' }
  ]).onConflictDoNothing();

  // Explicit seed IDs must advance PostgreSQL sequences for later API inserts.
  const sequenceColumns = {
    departments: 'department_id',
    doctors: 'doctor_id',
    doctor_schedules: 'schedule_id',
    staff_users: 'user_id',
    patients: 'patient_id'
  };
  for (const [table, column] of Object.entries(sequenceColumns)) {
    await db.execute(sql.raw(
      `SELECT setval(pg_get_serial_sequence('${table}', '${column}'), COALESCE((SELECT MAX(${column}) FROM ${table}), 1), true)`
    ));
  }

  console.log('Neon/Drizzle MVP seed completed. Development password: password');
}

seed()
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await closeDatabase();
  });
