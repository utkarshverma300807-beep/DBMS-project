// Notifications are intentionally deferred in the MVP. Appointment PDFs are
// generated locally; email/SMS delivery will be added after the core flow works.
async function createAppointmentNotifications() {
  return { queued: false, reason: 'Deferred until notification provider is configured.' };
}

module.exports = { createAppointmentNotifications };
