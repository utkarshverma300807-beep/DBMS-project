DO $$ BEGIN
 CREATE TYPE "public"."gender" AS ENUM('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "public"."staff_role" AS ENUM('ADMIN', 'RECEPTIONIST', 'DOCTOR');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "public"."appointment_priority" AS ENUM('NORMAL', 'URGENT', 'EMERGENCY');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "public"."appointment_status" AS ENUM('BOOKED', 'CHECKED_IN', 'WAITING', 'CALLED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 CREATE TYPE "public"."emergency_level" AS ENUM('URGENT', 'CRITICAL');
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "patients" (
	"patient_id" serial PRIMARY KEY NOT NULL,
	"phone_number" varchar(20) NOT NULL,
	"first_name" varchar(100) NOT NULL,
	"last_name" varchar(100),
	"date_of_birth" date,
	"gender" "gender",
	"blood_group" varchar(5),
	"address" text,
	"emergency_contact_name" varchar(150),
	"emergency_contact_phone" varchar(20),
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "patients_phone_number_unique" UNIQUE("phone_number")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "departments" (
	"department_id" serial PRIMARY KEY NOT NULL,
	"department_name" varchar(150) NOT NULL,
	"department_code" varchar(20) NOT NULL,
	"description" text,
	"location" varchar(255),
	"active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "departments_department_name_unique" UNIQUE("department_name"),
	CONSTRAINT "departments_department_code_unique" UNIQUE("department_code")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "doctors" (
	"doctor_id" serial PRIMARY KEY NOT NULL,
	"first_name" varchar(100) NOT NULL,
	"last_name" varchar(100),
	"phone_number" varchar(20),
	"email" varchar(255),
	"specialization" varchar(150) NOT NULL,
	"license_number" varchar(100) NOT NULL,
	"default_room_number" varchar(50),
	"active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "doctors_email_unique" UNIQUE("email"),
	CONSTRAINT "doctors_license_number_unique" UNIQUE("license_number")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "staff_users" (
	"user_id" serial PRIMARY KEY NOT NULL,
	"username" varchar(100) NOT NULL,
	"email" varchar(255),
	"password_hash" varchar(255) NOT NULL,
	"role" "staff_role" NOT NULL,
	"doctor_id" integer,
	"active" boolean DEFAULT true NOT NULL,
	"last_login_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "staff_users_username_unique" UNIQUE("username"),
	CONSTRAINT "staff_users_email_unique" UNIQUE("email"),
	CONSTRAINT "staff_users_doctor_id_unique" UNIQUE("doctor_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "doctor_departments" (
	"doctor_id" integer NOT NULL,
	"department_id" integer NOT NULL,
	"is_primary_department" boolean DEFAULT false NOT NULL,
	"assigned_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "doctor_departments_doctor_id_department_id_pk" PRIMARY KEY("doctor_id","department_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "doctor_schedules" (
	"schedule_id" serial PRIMARY KEY NOT NULL,
	"doctor_id" integer NOT NULL,
	"department_id" integer NOT NULL,
	"day_of_week" integer NOT NULL,
	"start_time" time NOT NULL,
	"end_time" time NOT NULL,
	"max_appointments" integer DEFAULT 20 NOT NULL,
	"active" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "appointments" (
	"appointment_id" serial PRIMARY KEY NOT NULL,
	"appointment_number" varchar(50) NOT NULL,
	"patient_id" integer NOT NULL,
	"doctor_id" integer NOT NULL,
	"department_id" integer NOT NULL,
	"appointment_date" date NOT NULL,
	"appointment_time" time,
	"token_number" integer,
	"symptoms" text NOT NULL,
	"medical_notes" text,
	"priority" "appointment_priority" DEFAULT 'NORMAL' NOT NULL,
	"status" "appointment_status" DEFAULT 'BOOKED' NOT NULL,
	"room_number" varchar(50),
	"cancellation_reason" varchar(500),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "appointments_appointment_number_unique" UNIQUE("appointment_number")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "emergency_records" (
	"emergency_id" serial PRIMARY KEY NOT NULL,
	"appointment_id" integer NOT NULL,
	"emergency_level" "emergency_level" NOT NULL,
	"emergency_description" text NOT NULL,
	"handled_immediately" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "emergency_records_appointment_id_unique" UNIQUE("appointment_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "appointment_status_history" (
	"history_id" serial PRIMARY KEY NOT NULL,
	"appointment_id" integer NOT NULL,
	"old_status" "appointment_status",
	"new_status" "appointment_status" NOT NULL,
	"changed_by" integer,
	"change_reason" varchar(500),
	"changed_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "staff_users" ADD CONSTRAINT "staff_users_doctor_id_doctors_doctor_id_fk" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctors"("doctor_id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "doctor_departments" ADD CONSTRAINT "doctor_departments_doctor_id_doctors_doctor_id_fk" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctors"("doctor_id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "doctor_departments" ADD CONSTRAINT "doctor_departments_department_id_departments_department_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("department_id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "doctor_schedules" ADD CONSTRAINT "doctor_schedules_doctor_department_fk" FOREIGN KEY ("doctor_id","department_id") REFERENCES "public"."doctor_departments"("doctor_id","department_id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "appointments" ADD CONSTRAINT "appointments_patient_id_patients_patient_id_fk" FOREIGN KEY ("patient_id") REFERENCES "public"."patients"("patient_id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "appointments" ADD CONSTRAINT "appointments_doctor_id_doctors_doctor_id_fk" FOREIGN KEY ("doctor_id") REFERENCES "public"."doctors"("doctor_id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "appointments" ADD CONSTRAINT "appointments_department_id_departments_department_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("department_id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "appointments" ADD CONSTRAINT "appointments_doctor_department_fk" FOREIGN KEY ("doctor_id","department_id") REFERENCES "public"."doctor_departments"("doctor_id","department_id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "emergency_records" ADD CONSTRAINT "emergency_records_appointment_id_appointments_appointment_id_fk" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("appointment_id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "appointment_status_history" ADD CONSTRAINT "appointment_status_history_appointment_id_appointments_appointment_id_fk" FOREIGN KEY ("appointment_id") REFERENCES "public"."appointments"("appointment_id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "appointment_status_history" ADD CONSTRAINT "appointment_status_history_changed_by_staff_users_user_id_fk" FOREIGN KEY ("changed_by") REFERENCES "public"."staff_users"("user_id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "patients_phone_idx" ON "patients" USING btree ("phone_number");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "doctors_active_idx" ON "doctors" USING btree ("active");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "doctor_departments_department_idx" ON "doctor_departments" USING btree ("department_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "doctor_schedules_lookup_idx" ON "doctor_schedules" USING btree ("department_id","day_of_week","active");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "appointments_queue_idx" ON "appointments" USING btree ("department_id","appointment_date","priority","status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "appointments_patient_date_idx" ON "appointments" USING btree ("patient_id","appointment_date");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "appointments_department_date_token_idx" ON "appointments" USING btree ("department_id","appointment_date","token_number");