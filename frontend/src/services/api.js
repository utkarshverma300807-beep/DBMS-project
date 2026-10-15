const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api';

async function request(path, options = {}) {
  const { token, ...fetchOptions } = options;
  const headers = new Headers(fetchOptions.headers || {});

  if (fetchOptions.body && !headers.has('Content-Type')) headers.set('Content-Type', 'application/json');
  if (token) headers.set('Authorization', `Bearer ${token}`);

  const response = await fetch(`${API_URL}${path}`, { ...fetchOptions, headers });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || 'The request could not be completed.');
  return data;
}

export function getPatientByPhone(phone) { return request(`/patients/phone/${encodeURIComponent(phone)}`); }
export function createPatient(patient) { return request('/patients', { method: 'POST', body: JSON.stringify(patient) }); }
export function getDepartments() { return request('/departments'); }
export function getDoctors(departmentId) { return request(`/doctors${departmentId ? `?department_id=${departmentId}` : ''}`); }
export function createAppointment(appointment) { return request('/appointments', { method: 'POST', body: JSON.stringify(appointment) }); }
export function login(credentials) { return request('/auth/login', { method: 'POST', body: JSON.stringify(credentials) }); }
export function getAppointments(token, filters = {}) {
  const query = new URLSearchParams(filters).toString();
  return request(`/appointments${query ? `?${query}` : ''}`, { token });
}
export function getQueue(departmentId, date) {
  return request(`/appointments/queue/${departmentId}${date ? `?date=${encodeURIComponent(date)}` : ''}`);
}
export function updateAppointmentStatus(id, status, reason, token) {
  return request(`/appointments/${id}/status`, { method: 'PUT', token, body: JSON.stringify({ status, reason }) });
}

export { API_URL };
