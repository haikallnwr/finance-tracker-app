const userService = require("../services/userService");
const asyncHandler = require("express-async-handler");

exports.getAllUser = asyncHandler(async (req, res) => {
  const users = await userService.getAllUsers();
  res.status(200).json(users);
});

exports.getUser = asyncHandler(async (req, res) => {
  const user = await userService.getUserById(req.user._id);
  res.status(200).json(user);
});

exports.updateUser = asyncHandler(async (req, res) => {
  const updatedUser = await userService.updateUserById(req.user._id, req.body);
  res.status(200).json({ update: updatedUser });
});
