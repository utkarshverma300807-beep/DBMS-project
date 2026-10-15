function notFound(req, res) {
  res.status(404).json({
    error: `Route not found: ${req.method} ${req.originalUrl}`
  });
}

function errorHandler(error, req, res, next) {
  console.error(error);

  if (res.headersSent) {
    return next(error);
  }

  if (error.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ error: 'A record with the same unique value already exists.' });
  }

  if (error.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({ error: 'A referenced record does not exist.' });
  }

  return res.status(error.statusCode || 500).json({
    error: error.statusCode ? error.message : 'Internal server error.'
  });
}

module.exports = { notFound, errorHandler };
