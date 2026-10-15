const { db } = require('../config/database');
const { appointments, patients, doctors, departments } = require('../db/schema');
const { eq, and, asc, sql } = require('drizzle-orm');
const { createAppointment, fetchAppointment, updateAppointmentStatus } = require('../services/appointment.service');

async function bookAppointment(req, res, next) {
  try { return res.status(201).json(await createAppointment(req.body, req.user)); }
  catch (error) { return next(error); }
}

async function getAppointment(req, res, next) {
  try {
    const appointment = await fetchAppointment(db, Number(req.params.id));
    if (!appointment) return res.status(404).json({ error: 'Appointment was not found.' });
    return res.json(appointment);
  } catch (error) { return next(error); }
}

async function listAppointments(req, res, next) {
  try {
    const filters = [];
    if (req.query.date) filters.push(eq(appointments.appointmentDate, req.query.date));
    if (req.query.department_id) filters.push(eq(appointments.departmentId, Number(req.query.department_id)));
    if (req.query.doctor_id) filters.push(eq(appointments.doctorId, Number(req.query.doctor_id)));
    if (req.query.status) filters.push(eq(appointments.status, req.query.status));

    const rows = await db.select({
      appointmentId: appointments.appointmentId,
      appointmentNumber: appointments.appointmentNumber,
      appointmentDate: appointments.appointmentDate,
      appointmentTime: appointments.appointmentTime,
      tokenNumber: appointments.tokenNumber,
      priority: appointments.priority,
      status: appointments.status,
      roomNumber: appointments.roomNumber,
      patientId: patients.patientId,
      patientName: sql`concat(${patients.firstName}, ' ', coalesce(${patients.lastName}, ''))`,
      patientPhone: patients.phoneNumber,
      doctorId: doctors.doctorId,
      doctorName: sql`concat('Dr. ', ${doctors.firstName}, ' ', coalesce(${doctors.lastName}, ''))`,
      departmentId: departments.departmentId,
      departmentName: departments.departmentName
    }).from(appointments)
      .innerJoin(patients, eq(patients.patientId, appointments.patientId))
      .innerJoin(doctors, eq(doctors.doctorId, appointments.doctorId))
      .innerJoin(departments, eq(departments.departmentId, appointments.departmentId))
      .where(filters.length ? and(...filters) : undefined)
      .orderBy(asc(appointments.appointmentDate), asc(appointments.appointmentTime), asc(appointments.tokenNumber));
    return res.json(rows);
  } catch (error) { return next(error); }
}

async function updateStatus(req, res, next) {
  try {
    return res.json(await updateAppointmentStatus(req.params.id, req.body.status, req.user, req.body.reason || null));
  } catch (error) { return next(error); }
}

async function cancelAppointment(req, res, next) {
  try {
    return res.json(await updateAppointmentStatus(req.params.id, 'CANCELLED', req.user, req.body.reason));
  } catch (error) { return next(error); }
}

async function getQueue(req, res, next) {
  try {
    const date = req.query.date || new Date().toISOString().slice(0, 10);
    const rows = await db.select({
      appointmentId: appointments.appointmentId,
      appointmentNumber: appointments.appointmentNumber,
      tokenNumber: appointments.tokenNumber,
      priority: appointments.priority,
      status: appointments.status,
      roomNumber: appointments.roomNumber,
      patientName: sql`concat(${patients.firstName}, ' ', coalesce(${patients.lastName}, ''))`,
      doctorName: sql`concat('Dr. ', ${doctors.firstName}, ' ', coalesce(${doctors.lastName}, ''))`
    }).from(appointments)
      .innerJoin(patients, eq(patients.patientId, appointments.patientId))
      .innerJoin(doctors, eq(doctors.doctorId, appointments.doctorId))
      .where(and(
        eq(appointments.departmentId, Number(req.params.departmentId)),
        eq(appointments.appointmentDate, date),
        sql`${appointments.status} IN ('CHECKED_IN', 'WAITING', 'CALLED', 'IN_PROGRESS')`
      ))
      .orderBy(asc(appointments.priority), asc(appointments.tokenNumber));
    return res.json(rows);
  } catch (error) { return next(error); }
}

module.exports = { bookAppointment, getAppointment, listAppointments, updateStatus, cancelAppointment, getQueue };
