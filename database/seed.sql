-- Hospital Management System
-- Phase 3: development and demonstration seed data
-- Safe to re-run: all rows use stable primary/unique keys with upserts.
-- Do not use these development credentials in production.

USE hospital_management;

SET @today = CURRENT_DATE();
SET @tomorrow = DATE_ADD(@today, INTERVAL 1 DAY);
SET @yesterday = DATE_SUB(@today, INTERVAL 1 DAY);

START TRANSACTION;

-- -----------------------------------------------------------------------------
-- Departments
-- -----------------------------------------------------------------------------

INSERT INTO departments
    (department_id, department_name, department_code, description, location, active)
VALUES
    (1, 'General Medicine', 'GEN',
        'Diagnosis and treatment of common adult health conditions.',
        'Main Building - Ground Floor', TRUE),
    (2, 'Cardiology', 'CAR',
        'Heart and cardiovascular care.',
        'Main Building - First Floor', TRUE),
    (3, 'Neurology', 'NEU',
        'Diagnosis and treatment of nervous-system conditions.',
        'Main Building - Second Floor', TRUE),
    (4, 'Orthopedics', 'ORT',
        'Bone, joint, muscle, and mobility care.',
        'Specialty Block - Ground Floor', TRUE),
    (5, 'Emergency', 'ER',
        'Immediate assessment and treatment of urgent and critical cases.',
        'Emergency Block', TRUE)
ON DUPLICATE KEY UPDATE
    department_name = VALUES(department_name),
    description = VALUES(description),
    location = VALUES(location),
    active = VALUES(active);

-- -----------------------------------------------------------------------------
-- Doctors
-- -----------------------------------------------------------------------------

INSERT INTO doctors
    (doctor_id, first_name, last_name, phone_number, email, specialization,
     license_number, default_room_number, active)
VALUES
    (1, 'Aarav', 'Sharma', '+91-9000000001', 'aarav.sharma@hospital.test',
        'General Physician', 'LIC-GEN-001', 'G-101', TRUE),
    (2, 'Meera', 'Nair', '+91-9000000002', 'meera.nair@hospital.test',
        'Cardiologist', 'LIC-CAR-001', 'C-201', TRUE),
    (3, 'Kabir', 'Verma', '+91-9000000003', 'kabir.verma@hospital.test',
        'Neurologist', 'LIC-NEU-001', 'N-301', TRUE),
    (4, 'Ishita', 'Patel', '+91-9000000004', 'ishita.patel@hospital.test',
        'Orthopedic Surgeon', 'LIC-ORT-001', 'O-401', TRUE),
    (5, 'Rohan', 'Iyer', '+91-9000000005', 'rohan.iyer@hospital.test',
        'Emergency Physician', 'LIC-ER-001', 'E-001', TRUE),
    (6, 'Ananya', 'Rao', '+91-9000000006', 'ananya.rao@hospital.test',
        'Emergency Physician', 'LIC-ER-002', 'E-002', TRUE)
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    phone_number = VALUES(phone_number),
    email = VALUES(email),
    specialization = VALUES(specialization),
    default_room_number = VALUES(default_room_number),
    active = VALUES(active);

-- -----------------------------------------------------------------------------
-- Doctor assignments
-- -----------------------------------------------------------------------------

INSERT INTO doctor_departments
    (doctor_id, department_id, is_primary_department)
VALUES
    (1, 1, TRUE),
    (2, 2, TRUE),
    (3, 3, TRUE),
    (4, 4, TRUE),
    (5, 5, TRUE),
    (6, 5, TRUE),
    (1, 5, FALSE)
ON DUPLICATE KEY UPDATE
    is_primary_department = VALUES(is_primary_department);

-- -----------------------------------------------------------------------------
-- Recurring weekly schedules
-- -----------------------------------------------------------------------------

INSERT INTO doctor_schedules
    (schedule_id, doctor_id, department_id, day_of_week,
     start_time, end_time, max_appointments, active)
VALUES
    (1, 1, 1, 1, '09:00:00', '13:00:00', 24, TRUE),
    (2, 1, 1, 3, '09:00:00', '13:00:00', 24, TRUE),
    (3, 1, 1, 5, '09:00:00', '13:00:00', 24, TRUE),
    (4, 2, 2, 2, '10:00:00', '14:00:00', 16, TRUE),
    (5, 2, 2, 4, '10:00:00', '14:00:00', 16, TRUE),
    (6, 3, 3, 2, '09:00:00', '13:00:00', 16, TRUE),
    (7, 3, 3, 6, '09:00:00', '12:00:00', 12, TRUE),
    (8, 4, 4, 1, '11:00:00', '15:00:00', 16, TRUE),
    (9, 4, 4, 4, '11:00:00', '15:00:00', 16, TRUE),
    (10, 5, 5, 1, '00:00:00', '23:59:00', 50, TRUE),
    (11, 6, 5, 1, '00:00:00', '23:59:00', 50, TRUE)
ON DUPLICATE KEY UPDATE
    start_time = VALUES(start_time),
    end_time = VALUES(end_time),
    max_appointments = VALUES(max_appointments),
    active = VALUES(active);

-- -----------------------------------------------------------------------------
-- Staff accounts
-- Password hash is a development-only bcrypt value.
-- Development password for all seeded accounts: password
-- -----------------------------------------------------------------------------

INSERT INTO staff_users
    (user_id, username, email, password_hash, role, doctor_id, active)
VALUES
    (1, 'admin', 'admin@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'ADMIN', NULL, TRUE),
    (2, 'reception', 'reception@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'RECEPTIONIST', NULL, TRUE),
    (3, 'doctor.aarav', 'aarav.login@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'DOCTOR', 1, TRUE),
    (4, 'doctor.meera', 'meera.login@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'DOCTOR', 2, TRUE),
    (5, 'doctor.kabir', 'kabir.login@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'DOCTOR', 3, TRUE),
    (6, 'doctor.ishita', 'ishita.login@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'DOCTOR', 4, TRUE),
    (7, 'doctor.rohan', 'rohan.login@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'DOCTOR', 5, TRUE),
    (8, 'doctor.ananya', 'ananya.login@hospital.test',
        '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'DOCTOR', 6, TRUE)
ON DUPLICATE KEY UPDATE
    email = VALUES(email),
    password_hash = VALUES(password_hash),
    role = VALUES(role),
    doctor_id = VALUES(doctor_id),
    active = VALUES(active);

-- -----------------------------------------------------------------------------
-- Patients
-- -----------------------------------------------------------------------------

INSERT INTO patients
    (patient_id, phone_number, first_name, last_name, date_of_birth, gender,
     blood_group, address, emergency_contact_name, emergency_contact_phone, is_active)
VALUES
    (1, '+91-9111111111', 'Priya', 'Shah', '1994-06-12', 'FEMALE', 'B+',
        'Pune, Maharashtra', 'Rahul Shah', '+91-9222222222', TRUE),
    (2, '+91-9333333333', 'Vikram', 'Joshi', '1987-11-03', 'MALE', 'O+',
        'Mumbai, Maharashtra', 'Neha Joshi', '+91-9444444444', TRUE),
    (3, '+91-9555555555', 'Nisha', 'Kapoor', '2001-02-21', 'FEMALE', 'A+',
        'Nashik, Maharashtra', 'Amit Kapoor', '+91-9666666666', TRUE),
    (4, '+91-9777777777', 'Arjun', 'Mehta', '1975-09-18', 'MALE', 'AB+',
        'Thane, Maharashtra', 'Kavita Mehta', '+91-9888888888', TRUE),
    (5, '+91-9000000099', 'Sana', 'Khan', '1990-04-09', 'FEMALE', 'O+',
        'Nagpur, Maharashtra', 'Imran Khan', '+91-9000000088', TRUE)
ON DUPLICATE KEY UPDATE
    first_name = VALUES(first_name),
    last_name = VALUES(last_name),
    date_of_birth = VALUES(date_of_birth),
    gender = VALUES(gender),
    blood_group = VALUES(blood_group),
    address = VALUES(address),
    emergency_contact_name = VALUES(emergency_contact_name),
    emergency_contact_phone = VALUES(emergency_contact_phone),
    is_active = VALUES(is_active);

-- -----------------------------------------------------------------------------
-- Appointments
-- -----------------------------------------------------------------------------

INSERT INTO appointments
    (appointment_id, appointment_number, patient_id, doctor_id, department_id,
     appointment_date, appointment_time, token_number, symptoms, medical_notes,
     priority, status, room_number, checked_in_at, called_at, completed_at,
     cancelled_at, cancellation_reason)
VALUES
    (1, 'APT-SEED-001', 1, 1, 1, @today, '09:30:00', 1,
        'Fever, sore throat, and fatigue for two days.', NULL,
        'NORMAL', 'WAITING', 'G-101', CURRENT_TIMESTAMP, NULL, NULL, NULL, NULL),
    (2, 'APT-SEED-002', 2, 2, 2, @today, '10:00:00', 1,
        'Chest discomfort after physical activity.', NULL,
        'URGENT', 'CHECKED_IN', 'C-201', CURRENT_TIMESTAMP, NULL, NULL, NULL, NULL),
    (3, 'APT-SEED-003', 3, 3, 3, @tomorrow, '09:30:00', 1,
        'Recurring headache and occasional dizziness.', NULL,
        'NORMAL', 'BOOKED', 'N-301', NULL, NULL, NULL, NULL, NULL),
    (4, 'APT-SEED-004', 4, 5, 5, @today, NULL, NULL,
        'Severe breathing difficulty and sudden chest pain.', NULL,
        'EMERGENCY', 'IN_PROGRESS', 'E-001', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        NULL, NULL, NULL),
    (5, 'APT-SEED-005', 5, 4, 4, @yesterday, '11:30:00', 1,
        'Knee pain after a sports injury.', 'X-ray requested.',
        'NORMAL', 'COMPLETED', 'O-401', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP, NULL, NULL),
    (6, 'APT-SEED-006', 1, 1, 1, @yesterday, '10:30:00', 2,
        'Follow-up for persistent cough.', 'Follow-up consultation.',
        'NORMAL', 'CANCELLED', 'G-101', NULL, NULL, NULL, CURRENT_TIMESTAMP,
        'Patient requested cancellation.')
ON DUPLICATE KEY UPDATE
    patient_id = VALUES(patient_id),
    doctor_id = VALUES(doctor_id),
    department_id = VALUES(department_id),
    appointment_date = VALUES(appointment_date),
    appointment_time = VALUES(appointment_time),
    token_number = VALUES(token_number),
    symptoms = VALUES(symptoms),
    medical_notes = VALUES(medical_notes),
    priority = VALUES(priority),
    status = VALUES(status),
    room_number = VALUES(room_number),
    checked_in_at = VALUES(checked_in_at),
    called_at = VALUES(called_at),
    completed_at = VALUES(completed_at),
    cancelled_at = VALUES(cancelled_at),
    cancellation_reason = VALUES(cancellation_reason);

-- -----------------------------------------------------------------------------
-- Emergency case details
-- -----------------------------------------------------------------------------

INSERT INTO emergency_records
    (emergency_id, appointment_id, emergency_level, emergency_description,
     handled_immediately, handled_by, handled_at)
VALUES
    (1, 4, 'CRITICAL',
        'Severe breathing difficulty with sudden chest pain reported at intake.',
        TRUE, 2, CURRENT_TIMESTAMP)
ON DUPLICATE KEY UPDATE
    emergency_level = VALUES(emergency_level),
    emergency_description = VALUES(emergency_description),
    handled_immediately = VALUES(handled_immediately),
    handled_by = VALUES(handled_by),
    handled_at = VALUES(handled_at);

-- -----------------------------------------------------------------------------
-- Generated appointment documents
-- -----------------------------------------------------------------------------

INSERT INTO appointment_documents
    (document_id, appointment_id, document_type, file_name, file_path)
VALUES
    (1, 1, 'APPOINTMENT_PDF', 'APT-SEED-001.pdf',
        'generated-pdfs/APT-SEED-001.pdf'),
    (2, 2, 'APPOINTMENT_PDF', 'APT-SEED-002.pdf',
        'generated-pdfs/APT-SEED-002.pdf'),
    (3, 3, 'APPOINTMENT_PDF', 'APT-SEED-003.pdf',
        'generated-pdfs/APT-SEED-003.pdf'),
    (4, 4, 'APPOINTMENT_PDF', 'APT-SEED-004.pdf',
        'generated-pdfs/APT-SEED-004.pdf'),
    (5, 5, 'APPOINTMENT_PDF', 'APT-SEED-005.pdf',
        'generated-pdfs/APT-SEED-005.pdf')
ON DUPLICATE KEY UPDATE
    appointment_id = VALUES(appointment_id),
    document_type = VALUES(document_type),
    file_name = VALUES(file_name),
    file_path = VALUES(file_path);

-- -----------------------------------------------------------------------------
-- Notification delivery examples
-- -----------------------------------------------------------------------------

INSERT INTO notifications
    (notification_id, appointment_id, recipient_type, patient_id, doctor_id,
     staff_user_id, notification_type, recipient_address, status, sent_at,
     error_message)
VALUES
    (1, 1, 'PATIENT', 1, NULL, NULL, 'PDF', '+91-9111111111', 'SENT',
        CURRENT_TIMESTAMP, NULL),
    (2, 1, 'DOCTOR', NULL, 1, NULL, 'PDF', 'aarav.sharma@hospital.test', 'SENT',
        CURRENT_TIMESTAMP, NULL),
    (3, 2, 'PATIENT', 2, NULL, NULL, 'SMS', '+91-9333333333', 'SENT',
        CURRENT_TIMESTAMP, NULL),
    (4, 4, 'DOCTOR', NULL, 5, NULL, 'SYSTEM', 'rohan.iyer@hospital.test', 'SENT',
        CURRENT_TIMESTAMP, NULL),
    (5, 4, 'ADMIN', NULL, NULL, 1, 'SYSTEM', 'admin@hospital.test', 'PENDING',
        NULL, NULL),
    (6, 3, 'PATIENT', 3, NULL, NULL, 'EMAIL', '+91-9555555555', 'FAILED',
        NULL, 'Development mail service is not configured.')
ON DUPLICATE KEY UPDATE
    appointment_id = VALUES(appointment_id),
    recipient_type = VALUES(recipient_type),
    patient_id = VALUES(patient_id),
    doctor_id = VALUES(doctor_id),
    staff_user_id = VALUES(staff_user_id),
    notification_type = VALUES(notification_type),
    recipient_address = VALUES(recipient_address),
    status = VALUES(status),
    sent_at = VALUES(sent_at),
    error_message = VALUES(error_message);

-- -----------------------------------------------------------------------------
-- Appointment status history
-- -----------------------------------------------------------------------------

INSERT INTO appointment_status_history
    (history_id, appointment_id, old_status, new_status, changed_by, change_reason)
VALUES
    (1, 1, 'BOOKED', 'CHECKED_IN', 2, 'Patient checked in at reception.'),
    (2, 1, 'CHECKED_IN', 'WAITING', 2, 'Patient added to department queue.'),
    (3, 2, 'BOOKED', 'CHECKED_IN', 2, 'Urgent patient checked in.'),
    (4, 4, 'BOOKED', 'CHECKED_IN', 2, 'Emergency case registered immediately.'),
    (5, 4, 'CHECKED_IN', 'WAITING', 2, 'Emergency case sent to emergency queue.'),
    (6, 4, 'WAITING', 'CALLED', 7, 'Emergency doctor called patient.'),
    (7, 4, 'CALLED', 'IN_PROGRESS', 7, 'Emergency consultation started.'),
    (8, 5, 'BOOKED', 'CHECKED_IN', 2, 'Patient checked in.'),
    (9, 5, 'CHECKED_IN', 'WAITING', 2, 'Patient added to orthopedic queue.'),
    (10, 5, 'WAITING', 'CALLED', 6, 'Orthopedic doctor called patient.'),
    (11, 5, 'CALLED', 'IN_PROGRESS', 6, 'Consultation started.'),
    (12, 5, 'IN_PROGRESS', 'COMPLETED', 6, 'Consultation completed.'),
    (13, 6, 'BOOKED', 'CANCELLED', 2, 'Patient requested cancellation.')
ON DUPLICATE KEY UPDATE
    appointment_id = VALUES(appointment_id),
    old_status = VALUES(old_status),
    new_status = VALUES(new_status),
    changed_by = VALUES(changed_by),
    change_reason = VALUES(change_reason);

-- -----------------------------------------------------------------------------
-- Administrative audit examples
-- -----------------------------------------------------------------------------

INSERT INTO audit_log
    (audit_id, user_id, action_type, table_name, record_id, action_details)
VALUES
    (1, 1, 'INSERT', 'departments', 1,
        JSON_OBJECT('source', 'seed', 'description', 'Created General Medicine department')),
    (2, 1, 'INSERT', 'doctors', 5,
        JSON_OBJECT('source', 'seed', 'description', 'Created emergency physician')),
    (3, 2, 'INSERT', 'appointments', 1,
        JSON_OBJECT('source', 'seed', 'description', 'Created normal appointment')),
    (4, 2, 'INSERT', 'appointments', 4,
        JSON_OBJECT('source', 'seed', 'description', 'Created emergency appointment'))
ON DUPLICATE KEY UPDATE
    user_id = VALUES(user_id),
    action_type = VALUES(action_type),
    table_name = VALUES(table_name),
    record_id = VALUES(record_id),
    action_details = VALUES(action_details);

COMMIT;

-- Quick verification summary after loading the seed data.
SELECT 'departments' AS entity, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'doctors', COUNT(*) FROM doctors
UNION ALL
SELECT 'patients', COUNT(*) FROM patients
UNION ALL
SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL
SELECT 'emergency_records', COUNT(*) FROM emergency_records
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications;
