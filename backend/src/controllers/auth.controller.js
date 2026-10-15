const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { db } = require('../config/database');
const env = require('../config/env');
const { staffUsers } = require('../db/schema');
const { eq, or, and } = require('drizzle-orm');

async function login(req, res, next) {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: 'username and password are required.' });
    }

    const rows = await db.select({
      userId: staffUsers.userId,
      username: staffUsers.username,
      passwordHash: staffUsers.passwordHash,
      role: staffUsers.role,
      doctorId: staffUsers.doctorId
    }).from(staffUsers).where(
      andActiveLogin(username)
    );

    if (rows.length === 0 || !(await bcrypt.compare(password, rows[0].passwordHash))) {
      return res.status(401).json({ error: 'Invalid username or password.' });
    }

    const user = rows[0];
    await db.update(staffUsers)
      .set({ lastLoginAt: new Date() })
      .where(eq(staffUsers.userId, user.userId));

    const token = jwt.sign(
      { user_id: user.userId, username: user.username, role: user.role, doctor_id: user.doctorId },
      env.jwtSecret,
      { expiresIn: env.jwtExpiresIn }
    );

    return res.json({
      token,
      user: {
        user_id: user.userId,
        username: user.username,
        role: user.role,
        doctor_id: user.doctorId
      }
    });
  } catch (error) {
    return next(error);
  }
}

function andActiveLogin(username) {
  return and(
    or(eq(staffUsers.username, username), eq(staffUsers.email, username)),
    eq(staffUsers.active, true)
  );
}

module.exports = { login };
