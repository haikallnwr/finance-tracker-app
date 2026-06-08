const User = require("../models/user");
const AppError = require("../utils/AppError");

exports.getAllUsers = async () => {
  return await User.find({});
};

exports.getUserById = async (userId) => {
  const user = await User.findById(userId).select("-password");
  if (!user) {
    throw new AppError("User not found", 404);
  }
  return user;
};

exports.updateUserById = async (userId, updateData) => {
  if (updateData.password) {
    throw new AppError("Password cannot be updated here", 400);
  }
  return await User.findByIdAndUpdate(userId, updateData, { new: true, runValidators: true }).select("-password");
};
