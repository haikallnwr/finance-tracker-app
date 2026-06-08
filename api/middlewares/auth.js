const jwt = require("jsonwebtoken");
const AppError = require("../utils/AppError");

const auth = (req, res, next) => {
  const tokenHeader = req.header("Authorization");

  if (!tokenHeader) {
    return next(new AppError("Access denied, no valid token provided.", 401));
  }

  try {
    const token = tokenHeader.startsWith("Bearer ") ? tokenHeader.split(" ")[1] : tokenHeader;
    const verified = jwt.verify(token, process.env.JWT_SECRET);
    req.user = verified;
    next();
  } catch (error) {
    next(new AppError("Invalid token", 401));
  }
};

module.exports = auth;
