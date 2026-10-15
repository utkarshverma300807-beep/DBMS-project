const { db } = require('../config/database');
const { patients } = require('../db/schema');
const { eq, and } = require('drizzle-orm');

async function createPatient(req, res, next) {
  try {
    const {
      phone_number: phoneNumber, first_name: firstName, last_name: lastName = null,
      date_of_birth: dateOfBirth = null, gender = null, blood_group: bloodGroup = null,
      address = null, emergency_contact_name: emergencyContactName = null,
      emergency_contact_phone: emergencyContactPhone = null
    } = req.body;

    if (!phoneNumber || !firstName) {
      return res.status(400).json({ error: 'phone_number and first_name are required.' });
    }

    const [patient] = await db.insert(patients).values({
      phoneNumber, firstName, lastName, dateOfBirth, gender, bloodGroup,
      address, emergencyContactName, emergencyContactPhone
    }).returning();
    return res.status(201).json(patient);
  } catch (error) {
    return next(error);
  }
}

async function getPatientByPhone(req, res, next) {
  try {
    const [patient] = await db.select().from(patients).where(and(
      eq(patients.phoneNumber, req.params.phone),
      eq(patients.isActive, true)
    ));
    if (!patient) return res.status(404).json({ error: 'Patient was not found.' });
    return res.json(patient);
  } catch (error) {
    return next(error);
  }
}

async function updatePatient(req, res, next) {
  try {
    const fieldMap = {
      first_name: 'firstName', last_name: 'lastName', date_of_birth: 'dateOfBirth',
      gender: 'gender', blood_group: 'bloodGroup', address: 'address',
      emergency_contact_name: 'emergencyContactName',
      emergency_contact_phone: 'emergencyContactPhone'
    };
    const updates = {};
    for (const [input, column] of Object.entries(fieldMap)) {
      if (req.body[input] !== undefined) updates[column] = req.body[input];
    }
    if (Object.keys(updates).length === 0) return res.status(400).json({ error: 'No supported fields were provided.' });

    updates.updatedAt = new Date();
    const [patient] = await db.update(patients).set(updates)
      .where(and(eq(patients.patientId, Number(req.params.id)), eq(patients.isActive, true)))
      .returning();
    if (!patient) return res.status(404).json({ error: 'Patient was not found.' });
    return res.json(patient);
  } catch (error) {
    return next(error);
  }
}

module.exports = { createPatient, getPatientByPhone, updatePatient };
