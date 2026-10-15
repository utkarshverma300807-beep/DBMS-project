const crypto = require('crypto');
const { db } = require('../config/database');
const {
  patients, departments, doctors, appointments, emergencyRecords, appointmentStatusHistory
} = require('../db/schema');
const { eq, and, asc } = require('drizzle-orm');
const { chooseDoctor } = require('./doctor-assignment.service');
const { getNextToken } = require('./token.service');
const { generateAppointmentPdf } = require('./pdf.service');

function required(value, name) {
  if (value === undefined || value === null || String(value).trim() === '') {
    const error = new Error(`${name} is required.`);
    error.statusCode = 400;
    throw error;
  }
}

async function fetchAppointment(client, appointmentId) {
  const [row] = await client.select({
    appointmentId: appointments.appointmentId,
    appointmentNumber: appointments.appointmentNumber,
    patientId: appointments.patientId,
    patientPhone: patients.phoneNumber,
    patientFirstName: patients.firstName,
    patientLastName: patients.lastName,
    doctorId: appointments.doctorId,
    doctorFirstName: doctors.firstName,
    doctorLastName: doctors.lastName,
    departmentId: appointments.departmentId,
    departmentName: departments.departmentName,
    appointmentDate: appointments.appointmentDate,
    appointmentTime: appointments.appointmentTime,
    tokenNumber: appointments.tokenNumber,
    symptoms: appointments.symptoms,
    medicalNotes: appointments.medicalNotes,
    priority: appointments.priority,
    status: appointments.status,
    roomNumber: appointments.roomNumber,
    cancellationReason: appointments.cancellationReason
  }).from(appointments)
    .innerJoin(patients, eq(patients.patientId, appointments.patientId))
    .innerJoin(doctors, eq(doctors.doctorId, appointments.doctorId))
    .innerJoin(departments, eq(departments.departmentId, appointments.departmentId))
    .where(eq(appointments.appointmentId, appointmentId));

  if (!row) return null;
  return row;
}

async function createAppointment(payload, actor) {
  const {
    patient_id: patientId, department_id: departmentId, appointment_date: appointmentDate,
    appointment_time: appointmentTime = null, symptoms, medical_notes: medicalNotes = null,
    priority = 'NORMAL', emergency_description: emergencyDescription = null,
    emergency_level: emergencyLevel = 'URGENT'
  } = payload;

  required(patientId, 'patient_id');
  required(departmentId, 'department_id');
  required(appointmentDate, 'appointment_date');
  required(symptoms, 'symptoms');
  if (!['NORMAL', 'URGENT', 'EMERGENCY'].includes(priority)) {
    const error = new Error('Invalid priority.'); error.statusCode = 400; throw error;
  }
  if (priority === 'EMERGENCY') required(emergencyDescription, 'emergency_description');

  const appointmentId = await db.transaction(async (tx) => {
    const [patient] = await tx.select({ id: patients.patientId }).from(patients).where(and(
      eq(patients.patientId, Number(patientId)), eq(patients.isActive, true)
    ));
    if (!patient) { const error = new Error('Active patient was not found.'); error.statusCode = 404; throw error; }

    const [department] = await tx.select({ id: departments.departmentId }).from(departments).where(and(
      eq(departments.departmentId, Number(departmentId)), eq(departments.active, true)
    ));
    if (!department) { const error = new Error('Active department was not found.'); error.statusCode = 404; throw error; }

    const doctor = await chooseDoctor(tx, {
      departmentId: Number(departmentId), appointmentDate, appointmentTime, priority
    });
    const tokenNumber = await getNextToken(tx, Number(departmentId), appointmentDate, priority);
    const [created] = await tx.insert(appointments).values({
      appointmentNumber: `PENDING-${crypto.randomUUID()}`,
      patientId: Number(patientId), doctorId: doctor.doctorId, departmentId: Number(departmentId),
      appointmentDate, appointmentTime, tokenNumber, symptoms, medicalNotes, priority,
      roomNumber: doctor.roomNumber
    }).returning({ id: appointments.appointmentId });

    const appointmentNumber = `APT-${String(appointmentDate).replace(/-/g, '')}-${String(created.id).padStart(6, '0')}`;
    await tx.update(appointments).set({ appointmentNumber, updatedAt: new Date() })
      .where(eq(appointments.appointmentId, created.id));
    await tx.insert(appointmentStatusHistory).values({
      appointmentId: created.id, newStatus: 'BOOKED', changedBy: actor?.user_id || null,
      changeReason: 'Appointment created'
    });
    if (priority === 'EMERGENCY') {
      await tx.insert(emergencyRecords).values({
        appointmentId: created.id, emergencyLevel: emergencyLevel === 'CRITICAL' ? 'CRITICAL' : 'URGENT',
        emergencyDescription
      });
    }
    return created.id;
  });

  const appointment = await fetchAppointment(db, appointmentId);
  try {
    const pdf = await generateAppointmentPdf(appointment);
    return { ...appointment, pdfPath: pdf.relativePath };
  } catch (error) {
    console.error('PDF generation failed:', error.message);
    return appointment;
  }
}

async function updateAppointmentStatus(appointmentId, status, actor, reason = null) {
  const allowed = ['CHECKED_IN', 'WAITING', 'CALLED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'];
  if (!allowed.includes(status)) { const error = new Error('Invalid appointment status.'); error.statusCode = 400; throw error; }

  const appointment = await db.transaction(async (tx) => {
    const [current] = await tx.select({ status: appointments.status }).from(appointments)
      .where(eq(appointments.appointmentId, Number(appointmentId))).for('update');
    if (!current) { const error = new Error('Appointment was not found.'); error.statusCode = 404; throw error; }
    const updates = { status, updatedAt: new Date() };
    if (status === 'CANCELLED') updates.cancellationReason = reason || 'Cancelled by staff.';
    await tx.update(appointments).set(updates).where(eq(appointments.appointmentId, Number(appointmentId)));
    await tx.insert(appointmentStatusHistory).values({
      appointmentId: Number(appointmentId), oldStatus: current.status, newStatus: status,
      changedBy: actor?.user_id || null, changeReason: reason
    });
    return fetchAppointment(tx, Number(appointmentId));
  });
  return appointment;
}

module.exports = { createAppointment, fetchAppointment, updateAppointmentStatus };
