const { appointments } = require('../db/schema');
const { and, eq, isNotNull, sql, desc } = require('drizzle-orm');

async function getNextToken(tx, departmentId, appointmentDate, priority) {
  if (priority === 'EMERGENCY') return null;

  // Serialize token allocation for this department/date inside the transaction.
  await tx.execute(sql`SELECT pg_advisory_xact_lock(hashtext(${`${departmentId}:${appointmentDate}`}))`);
  const rows = await tx.select({ tokenNumber: appointments.tokenNumber })
    .from(appointments)
    .where(and(
      eq(appointments.departmentId, departmentId),
      eq(appointments.appointmentDate, appointmentDate),
      isNotNull(appointments.tokenNumber)
    ))
    .orderBy(desc(appointments.tokenNumber));

  return (rows[0]?.tokenNumber || 0) + 1;
}

module.exports = { getNextToken };
