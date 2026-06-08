const authService = require("../services/authService");
const asyncHandler = require("express-async-handler");

exports.register = asyncHandler(async (req, res) => {
  const { username, email, password } = req.body;
  const user = await authService.registerUser(username, email, password);
  res.status(201).json({ message: "User Successfuly created", user });
});

exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const result = await authService.loginUser(email, password);
  res.status(200).json({
    message: "Login Successful",
    token: result.token,
    user: {
      id: result.user._id,
      username: result.user.username,
      email: result.user.email,
    },
  });
});

exports.logout = (req, res) => {
  res.status(200).json({ message: "Logged out successfully" });
};

exports.changePassword = asyncHandler(async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  await authService.changeUserPassword(req.user._id, oldPassword, newPassword);
  res.status(200).json({ message: "Password updated" });
});
