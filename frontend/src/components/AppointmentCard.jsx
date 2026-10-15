export default function AppointmentCard({ appointment }) {
  return (
    <article>
      <h2>{appointment.appointmentNumber}</h2>
      <p>Status: {appointment.status}</p>
      <p>Token: {appointment.tokenNumber || 'Emergency priority'}</p>
    </article>
  );
}
