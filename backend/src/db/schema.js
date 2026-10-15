const {
  pgTable,
  pgEnum,
  serial,
  integer,
  varchar,
  text,
  date,
  time,
  timestamp,
  boolean,
  primaryKey,
  foreignKey,
  uniqueIndex,
  index,
  check
} = require('drizzle-orm/pg-core');
const { sql } = require('drizzle-orm');

const genderEnum = pgEnum('gender', ['MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY']);
const roleEnum = pgEnum('staff_role', ['ADMIN', 'RECEPTIONIST', 'DOCTOR']);
const priorityEnum = pgEnum('appointment_priority', ['NORMAL', 'URGENT', 'EMERGENCY']);
const appointmentStatusEnum = pgEnum('appointment_status', [
  'BOOKED', 'CHECKED_IN', 'WAITING', 'CALLED', 'IN_PROGRESS',
  'COMPLETED', 'CANCELLED', 'NO_SHOW'
]);
const emergencyLevelEnum = pgEnum('emergency_level', ['URGENT', 'CRITICAL']);

const patients = pgTable('patients', {
  patientId: serial('patient_id').primaryKey(),
  phoneNumber: varchar('phone_number', { length: 20 }).notNull().unique(),
  firstName: varchar('first_name', { length: 100 }).notNull(),
  lastName: varchar('last_name', { length: 100 }),
  dateOfBirth: date('date_of_birth'),
  gender: genderEnum('gender'),
  bloodGroup: varchar('blood_group', { length: 5 }),
  address: text('address'),
  emergencyContactName: varchar('emergency_contact_name', { length: 150 }),
  emergencyContactPhone: varchar('emergency_contact_phone', { length: 20 }),
  isActive: boolean('is_active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow()
}, (table) => ({
  phoneLength: check('patients_phone_length', sql`char_length(trim(${table.phoneNumber})) >= 7`),
  phoneIndex: index('patients_phone_idx').on(table.phoneNumber)
}));

const departments = pgTable('departments', {
  departmentId: serial('department_id').primaryKey(),
  departmentName: varchar('department_name', { length: 150 }).notNull().unique(),
  departmentCode: varchar('department_code', { length: 20 }).notNull().unique(),
  description: text('description'),
  location: varchar('location', { length: 255 }),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow()
});

const doctors = pgTable('doctors', {
  doctorId: serial('doctor_id').primaryKey(),
  firstName: varchar('first_name', { length: 100 }).notNull(),
  lastName: varchar('last_name', { length: 100 }),
  phoneNumber: varchar('phone_number', { length: 20 }),
  email: varchar('email', { length: 255 }).unique(),
  specialization: varchar('specialization', { length: 150 }).notNull(),
  licenseNumber: varchar('license_number', { length: 100 }).notNull().unique(),
  defaultRoomNumber: varchar('default_room_number', { length: 50 }),
  active: boolean('active').notNull().default(true),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow()
}, (table) => ({
  activeIndex: index('doctors_active_idx').on(table.active)
}));

const staffUsers = pgTable('staff_users', {
  userId: serial('user_id').primaryKey(),
  username: varchar('username', { length: 100 }).notNull().unique(),
  email: varchar('email', { length: 255 }).unique(),
  passwordHash: varchar('password_hash', { length: 255 }).notNull(),
  role: roleEnum('role').notNull(),
  doctorId: integer('doctor_id').references(() => doctors.doctorId, { onDelete: 'set null' }).unique(),
  active: boolean('active').notNull().default(true),
  lastLoginAt: timestamp('last_login_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow()
});

const doctorDepartments = pgTable('doctor_departments', {
  doctorId: integer('doctor_id').notNull().references(() => doctors.doctorId, { onDelete: 'cascade' }),
  departmentId: integer('department_id').notNull().references(() => departments.departmentId, { onDelete: 'cascade' }),
  isPrimaryDepartment: boolean('is_primary_department').notNull().default(false),
  assignedAt: timestamp('assigned_at', { withTimezone: true }).notNull().defaultNow()
}, (table) => ({
  pk: primaryKey({ columns: [table.doctorId, table.departmentId] }),
  departmentIndex: index('doctor_departments_department_idx').on(table.departmentId)
}));

const doctorSchedules = pgTable('doctor_schedules', {
  scheduleId: serial('schedule_id').primaryKey(),
  doctorId: integer('doctor_id').notNull(),
  departmentId: integer('department_id').notNull(),
  dayOfWeek: integer('day_of_week').notNull(),
  startTime: time('start_time').notNull(),
  endTime: time('end_time').notNull(),
  maxAppointments: integer('max_appointments').notNull().default(20),
  active: boolean('active').notNull().default(true)
}, (table) => ({
  assignmentFk: foreignKey({
    name: 'doctor_schedules_doctor_department_fk',
    columns: [table.doctorId, table.departmentId],
    foreignColumns: [doctorDepartments.doctorId, doctorDepartments.departmentId]
  }).onDelete('cascade'),
  dayCheck: check('doctor_schedule_day_check', sql`${table.dayOfWeek} BETWEEN 1 AND 7`),
  timeCheck: check('doctor_schedule_time_check', sql`${table.startTime} < ${table.endTime}`),
  lookupIndex: index('doctor_schedules_lookup_idx').on(table.departmentId, table.dayOfWeek, table.active)
}));

const appointments = pgTable('appointments', {
  appointmentId: serial('appointment_id').primaryKey(),
  appointmentNumber: varchar('appointment_number', { length: 50 }).notNull().unique(),
  patientId: integer('patient_id').notNull().references(() => patients.patientId, { onDelete: 'restrict' }),
  doctorId: integer('doctor_id').notNull().references(() => doctors.doctorId, { onDelete: 'restrict' }),
  departmentId: integer('department_id').notNull().references(() => departments.departmentId, { onDelete: 'restrict' }),
  appointmentDate: date('appointment_date').notNull(),
  appointmentTime: time('appointment_time'),
  tokenNumber: integer('token_number'),
  symptoms: text('symptoms').notNull(),
  medicalNotes: text('medical_notes'),
  priority: priorityEnum('priority').notNull().default('NORMAL'),
  status: appointmentStatusEnum('status').notNull().default('BOOKED'),
  roomNumber: varchar('room_number', { length: 50 }),
  cancellationReason: varchar('cancellation_reason', { length: 500 }),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow()
}, (table) => ({
  doctorDepartmentFk: foreignKey({
    name: 'appointments_doctor_department_fk',
    columns: [table.doctorId, table.departmentId],
    foreignColumns: [doctorDepartments.doctorId, doctorDepartments.departmentId]
  }).onDelete('restrict'),
  queueIndex: index('appointments_queue_idx').on(table.departmentId, table.appointmentDate, table.priority, table.status),
  patientDateIndex: index('appointments_patient_date_idx').on(table.patientId, table.appointmentDate),
  queueUnique: uniqueIndex('appointments_department_date_token_idx').on(table.departmentId, table.appointmentDate, table.tokenNumber)
}));

const emergencyRecords = pgTable('emergency_records', {
  emergencyId: serial('emergency_id').primaryKey(),
  appointmentId: integer('appointment_id').notNull().unique().references(() => appointments.appointmentId, { onDelete: 'cascade' }),
  emergencyLevel: emergencyLevelEnum('emergency_level').notNull(),
  emergencyDescription: text('emergency_description').notNull(),
  handledImmediately: boolean('handled_immediately').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow()
});

const appointmentStatusHistory = pgTable('appointment_status_history', {
  historyId: serial('history_id').primaryKey(),
  appointmentId: integer('appointment_id').notNull().references(() => appointments.appointmentId, { onDelete: 'cascade' }),
  oldStatus: appointmentStatusEnum('old_status'),
  newStatus: appointmentStatusEnum('new_status').notNull(),
  changedBy: integer('changed_by').references(() => staffUsers.userId, { onDelete: 'set null' }),
  changeReason: varchar('change_reason', { length: 500 }),
  changedAt: timestamp('changed_at', { withTimezone: true }).notNull().defaultNow()
});

module.exports = {
  genderEnum,
  roleEnum,
  priorityEnum,
  appointmentStatusEnum,
  emergencyLevelEnum,
  patients,
  departments,
  doctors,
  staffUsers,
  doctorDepartments,
  doctorSchedules,
  appointments,
  emergencyRecords,
  appointmentStatusHistory
};
