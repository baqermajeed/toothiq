function AppError(message, statusCode = 500, code = 'INTERNAL_ERROR') {
  const err = new Error(message);
  err.statusCode = statusCode;
  err.code = code;
  return err;
}

function unauthorized(message = 'Unauthorized') {
  return AppError(message, 401, 'UNAUTHORIZED');
}

function forbidden(message = 'Forbidden') {
  return AppError(message, 403, 'FORBIDDEN');
}

function notFound(message = 'Resource not found') {
  return AppError(message, 404, 'NOT_FOUND');
}

function badRequest(message = 'Bad request', code = 'BAD_REQUEST') {
  return AppError(message, 400, code);
}

function conflict(message = 'Conflict') {
  return AppError(message, 409, 'CONFLICT');
}

function unprocessable(message = 'Unprocessable entity') {
  return AppError(message, 422, 'UNPROCESSABLE');
}

module.exports = {
  AppError,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  conflict,
  unprocessable,
};
