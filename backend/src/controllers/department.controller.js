const { db } = require('../config/database');
const { departments } = require('../db/schema');
const { eq, asc } = require('drizzle-orm');

async function listDepartments(req, res, next) {
  try {
    const rows = await db.select().from(departments)
      .where(eq(departments.active, true))
      .orderBy(asc(departments.departmentName));
    return res.json(rows);
  } catch (error) {
    return next(error);
  }
}

async function createDepartment(req, res, next) {
  try {
    const { department_name: name, department_code: code, description = null, location = null } = req.body;
    if (!name || !code) return res.status(400).json({ error: 'department_name and department_code are required.' });
    const [department] = await db.insert(departments).values({
      departmentName: name, departmentCode: code, description, location
    }).returning();
    return res.status(201).json(department);
  } catch (error) {
    return next(error);
  }
}

async function updateDepartment(req, res, next) {
  try {
    const updates = {};
    if (req.body.department_name !== undefined) updates.departmentName = req.body.department_name;
    if (req.body.description !== undefined) updates.description = req.body.description;
    if (req.body.location !== undefined) updates.location = req.body.location;
    if (req.body.active !== undefined) updates.active = req.body.active;
    if (Object.keys(updates).length === 0) return res.status(400).json({ error: 'No supported fields were provided.' });

    const [department] = await db.update(departments).set(updates)
      .where(eq(departments.departmentId, Number(req.params.id))).returning();
    if (!department) return res.status(404).json({ error: 'Department was not found.' });
    return res.json(department);
  } catch (error) {
    return next(error);
  }
}

module.exports = { listDepartments, createDepartment, updateDepartment };
