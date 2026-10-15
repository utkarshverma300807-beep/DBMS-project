const { doctors, doctorDepartments, doctorSchedules, appointments } = require('../db/schema');
const { eq, and, count, notInArray } = require('drizzle-orm');

function dayOfWeek(dateString) {
  const day = new Date(`${dateString}T00:00:00Z`).getUTCDay();
  return day === 0 ? 7 : day;
}

async function chooseDoctor(tx, { departmentId, appointmentDate, appointmentTime, priority }) {
  const candidates = await tx.select({
    doctorId: doctors.doctorId,
    firstName: doctors.firstName,
    lastName: doctors.lastName,
    roomNumber: doctors.defaultRoomNumber
  }).from(doctors)
    .innerJoin(doctorDepartments, eq(doctorDepartments.doctorId, doctors.doctorId))
    .where(and(
      eq(doctorDepartments.departmentId, departmentId),
      eq(doctors.active, true)
    ));

  const available = [];
  for (const doctor of candidates) {
    let scheduled = priority === 'EMERGENCY';
    if (!scheduled) {
      const schedules = await tx.select().from(doctorSchedules).where(and(
        eq(doctorSchedules.doctorId, doctor.doctorId),
        eq(doctorSchedules.departmentId, departmentId),
        eq(doctorSchedules.dayOfWeek, dayOfWeek(appointmentDate)),
        eq(doctorSchedules.active, true)
      ));
      scheduled = schedules.some((schedule) => (
        !appointmentTime || (appointmentTime >= schedule.startTime && appointmentTime < schedule.endTime)
      ));
    }
    if (!scheduled) continue;

    const [load] = await tx.select({ total: count() }).from(appointments).where(and(
      eq(appointments.doctorId, doctor.doctorId),
      eq(appointments.appointmentDate, appointmentDate),
      notInArray(appointments.status, ['CANCELLED', 'NO_SHOW'])
    ));
    available.push({ ...doctor, load: Number(load.total) });
  }

  available.sort((a, b) => a.load - b.load || a.doctorId - b.doctorId);
  if (!available[0]) {
    const error = new Error('No available doctor is scheduled for this department and time.');
    error.statusCode = 409;
    throw error;
  }
  return available[0];
}

module.exports = { chooseDoctor };
