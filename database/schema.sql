-- Hospital Management System
-- Phase 2: normalized MySQL 8 database schema
-- This script is intentionally non-destructive and can be run repeatedly.

CREATE DATABASE IF NOT EXISTS hospital_management
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE hospital_management;

-- -----------------------------------------------------------------------------
-- Reference and identity tables
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS patients (
    patient_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    phone_number VARCHAR(20) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NULL,
    date_of_birth DATE NULL,
    gender ENUM('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY') NULL,
    blood_group VARCHAR(5) NULL,
    address TEXT NULL,
    emergency_contact_name VARCHAR(150) NULL,
    emergency_contact_phone VARCHAR(20) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (patient_id),
    CONSTRAINT uq_patients_phone UNIQUE (phone_number),
    CONSTRAINT chk_patients_phone CHECK (CHAR_LENGTH(TRIM(phone_number)) >= 7)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS departments (
    department_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(150) NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    description TEXT NULL,
    location VARCHAR(255) NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (department_id),
    CONSTRAINT uq_departments_name UNIQUE (department_name),
    CONSTRAINT uq_departments_code UNIQUE (department_code)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS doctors (
    doctor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NULL,
    phone_number VARCHAR(20) NULL,
    email VARCHAR(255) NULL,
    specialization VARCHAR(150) NOT NULL,
    license_number VARCHAR(100) NOT NULL,
    default_room_number VARCHAR(50) NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (doctor_id),
    CONSTRAINT uq_doctors_email UNIQUE (email),
    CONSTRAINT uq_doctors_license UNIQUE (license_number),
    INDEX idx_doctors_active (active)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS staff_users (
    user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL,
    email VARCHAR(255) NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('ADMIN', 'RECEPTIONIST', 'DOCTOR') NOT NULL,
    doctor_id BIGINT UNSIGNED NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (user_id),
    CONSTRAINT uq_staff_users_username UNIQUE (username),
    CONSTRAINT uq_staff_users_email UNIQUE (email),
    CONSTRAINT uq_staff_users_doctor UNIQUE (doctor_id),
    CONSTRAINT fk_staff_users_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors (doctor_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    INDEX idx_staff_users_role_active (role, active)
) ENGINE = InnoDB;

-- A doctor may work in more than one department.
CREATE TABLE IF NOT EXISTS doctor_departments (
    doctor_id BIGINT UNSIGNED NOT NULL,
    department_id INT UNSIGNED NOT NULL,
    is_primary_department BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (doctor_id, department_id),
    CONSTRAINT fk_doctor_departments_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors (doctor_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_doctor_departments_department
        FOREIGN KEY (department_id) REFERENCES departments (department_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX idx_doctor_departments_department (department_id, doctor_id)
) ENGINE = InnoDB;

-- Recurring weekly schedule for a doctor in a department.
CREATE TABLE IF NOT EXISTS doctor_schedules (
    schedule_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    doctor_id BIGINT UNSIGNED NOT NULL,
    department_id INT UNSIGNED NOT NULL,
    day_of_week TINYINT UNSIGNED NOT NULL COMMENT '1 = Monday, 7 = Sunday',
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_appointments SMALLINT UNSIGNED NOT NULL DEFAULT 20,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (schedule_id),
    CONSTRAINT fk_doctor_schedules_assignment
        FOREIGN KEY (doctor_id, department_id)
        REFERENCES doctor_departments (doctor_id, department_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_doctor_schedules_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_doctor_schedules_time CHECK (start_time < end_time),
    CONSTRAINT chk_doctor_schedules_capacity CHECK (max_appointments > 0),
    INDEX idx_doctor_schedules_lookup (
        department_id, day_of_week, active, start_time
    ),
    INDEX idx_doctor_schedules_doctor (
        doctor_id, day_of_week, active
    )
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Appointment and queue tables
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS appointments (
    appointment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    appointment_number VARCHAR(50) NOT NULL,
    patient_id BIGINT UNSIGNED NOT NULL,
    doctor_id BIGINT UNSIGNED NOT NULL,
    department_id INT UNSIGNED NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NULL,
    token_number INT UNSIGNED NULL,
    symptoms TEXT NOT NULL,
    medical_notes TEXT NULL,
    priority ENUM('NORMAL', 'URGENT', 'EMERGENCY') NOT NULL DEFAULT 'NORMAL',
    status ENUM(
        'BOOKED',
        'CHECKED_IN',
        'WAITING',
        'CALLED',
        'IN_PROGRESS',
        'COMPLETED',
        'CANCELLED',
        'NO_SHOW'
    ) NOT NULL DEFAULT 'BOOKED',
    room_number VARCHAR(50) NULL,
    checked_in_at TIMESTAMP NULL,
    called_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    cancelled_at TIMESTAMP NULL,
    cancellation_reason VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (appointment_id),
    CONSTRAINT uq_appointments_number UNIQUE (appointment_number),
    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_doctor_department
        FOREIGN KEY (doctor_id, department_id)
        REFERENCES doctor_departments (doctor_id, department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_appointments_emergency_notes CHECK (
        priority <> 'EMERGENCY' OR CHAR_LENGTH(TRIM(symptoms)) > 0
    ),
    CONSTRAINT chk_appointments_cancel_reason CHECK (
        status <> 'CANCELLED' OR CHAR_LENGTH(TRIM(cancellation_reason)) > 0
    ),
    CONSTRAINT chk_appointments_completion_time CHECK (
        status <> 'COMPLETED' OR completed_at IS NOT NULL
    ),
    -- NULL token numbers are allowed for emergency cases that bypass the queue.
    CONSTRAINT uq_appointments_department_date_token
        UNIQUE (department_id, appointment_date, token_number),
    INDEX idx_appointments_patient_date (patient_id, appointment_date),
    INDEX idx_appointments_doctor_date_status (
        doctor_id, appointment_date, status
    ),
    INDEX idx_appointments_department_queue (
        department_id, appointment_date, priority, status, token_number
    ),
    INDEX idx_appointments_date_status (appointment_date, status)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS emergency_records (
    emergency_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    appointment_id BIGINT UNSIGNED NOT NULL,
    emergency_level ENUM('URGENT', 'CRITICAL') NOT NULL,
    emergency_description TEXT NOT NULL,
    handled_immediately BOOLEAN NOT NULL DEFAULT FALSE,
    handled_by BIGINT UNSIGNED NULL,
    handled_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (emergency_id),
    CONSTRAINT uq_emergency_records_appointment UNIQUE (appointment_id),
    CONSTRAINT fk_emergency_records_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_emergency_records_staff
        FOREIGN KEY (handled_by) REFERENCES staff_users (user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT chk_emergency_records_handled CHECK (
        handled_immediately = FALSE OR handled_at IS NOT NULL
    ),
    INDEX idx_emergency_records_active (handled_immediately, created_at)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS appointment_documents (
    document_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    appointment_id BIGINT UNSIGNED NOT NULL,
    document_type ENUM('APPOINTMENT_PDF', 'MEDICAL_REPORT', 'OTHER') NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (document_id),
    CONSTRAINT fk_appointment_documents_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    INDEX idx_appointment_documents_appointment (appointment_id, document_type)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
    notification_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    appointment_id BIGINT UNSIGNED NOT NULL,
    recipient_type ENUM('PATIENT', 'DOCTOR', 'ADMIN') NOT NULL,
    patient_id BIGINT UNSIGNED NULL,
    doctor_id BIGINT UNSIGNED NULL,
    staff_user_id BIGINT UNSIGNED NULL,
    notification_type ENUM('EMAIL', 'SMS', 'PDF', 'SYSTEM') NOT NULL,
    recipient_address VARCHAR(255) NULL,
    status ENUM('PENDING', 'SENT', 'FAILED') NOT NULL DEFAULT 'PENDING',
    sent_at TIMESTAMP NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (notification_id),
    CONSTRAINT fk_notifications_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_notifications_patient
        FOREIGN KEY (patient_id) REFERENCES patients (patient_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_notifications_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors (doctor_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_notifications_staff_user
        FOREIGN KEY (staff_user_id) REFERENCES staff_users (user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT chk_notifications_recipient CHECK (
        (recipient_type = 'PATIENT'
            AND patient_id IS NOT NULL
            AND doctor_id IS NULL
            AND staff_user_id IS NULL)
        OR
        (recipient_type = 'DOCTOR'
            AND patient_id IS NULL
            AND doctor_id IS NOT NULL
            AND staff_user_id IS NULL)
        OR
        (recipient_type = 'ADMIN'
            AND patient_id IS NULL
            AND doctor_id IS NULL
            AND staff_user_id IS NOT NULL)
    ),
    CONSTRAINT chk_notifications_sent_time CHECK (
        status <> 'SENT' OR sent_at IS NOT NULL
    ),
    INDEX idx_notifications_delivery (status, created_at),
    INDEX idx_notifications_appointment (appointment_id)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Audit and status history
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS appointment_status_history (
    history_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    appointment_id BIGINT UNSIGNED NOT NULL,
    old_status ENUM(
        'BOOKED', 'CHECKED_IN', 'WAITING', 'CALLED',
        'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    ) NULL,
    new_status ENUM(
        'BOOKED', 'CHECKED_IN', 'WAITING', 'CALLED',
        'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
    ) NOT NULL,
    changed_by BIGINT UNSIGNED NULL,
    change_reason VARCHAR(500) NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (history_id),
    CONSTRAINT fk_status_history_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments (appointment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_status_history_staff
        FOREIGN KEY (changed_by) REFERENCES staff_users (user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    INDEX idx_status_history_appointment (appointment_id, changed_at)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS audit_log (
    audit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT') NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT UNSIGNED NULL,
    action_details JSON NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (audit_id),
    CONSTRAINT fk_audit_log_user
        FOREIGN KEY (user_id) REFERENCES staff_users (user_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    INDEX idx_audit_log_table_record (table_name, record_id),
    INDEX idx_audit_log_user_date (user_id, created_at)
) ENGINE = InnoDB;
