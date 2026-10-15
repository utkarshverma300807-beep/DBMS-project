# Hospital Management API

## Local setup

1. Create a Neon PostgreSQL project.
2. Copy the root `.env.example` file to `.env`.
3. Set `DATABASE_URL` to the Neon connection string.
4. From the `backend` folder, run `npm install`.
5. Generate and apply the Drizzle migration with `npm run db:push`.
6. Load development data with `npm run db:seed`.
7. Start the API with `npm run dev`.

The API runs on `http://localhost:4000` by default.

## Endpoints

```text
GET  /health

POST /api/auth/login

POST /api/patients
GET  /api/patients/phone/:phone
PUT  /api/patients/:id                 Staff only

GET  /api/departments
POST /api/departments                  Admin only
PUT  /api/departments/:id              Admin only

GET  /api/doctors
POST /api/doctors                      Admin only

POST /api/appointments
GET  /api/appointments/:id
GET  /api/appointments/queue/:departmentId
GET  /api/appointments                 Staff only
PUT  /api/appointments/:id/status      Staff only
POST /api/appointments/:id/cancel      Staff only
```

Staff endpoints require:

```text
Authorization: Bearer <jwt-token>
```

The active MVP schema is `backend/src/db/schema.js`. The earlier MySQL files under `database/` are retained as historical reference and are not used by this backend.

Appointment creation runs in a PostgreSQL transaction. It validates the patient and department, assigns an available doctor, allocates a department token, records emergency details when needed, and generates the appointment PDF.
