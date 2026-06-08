const User = require("../models/user");
const Account = require("../models/account");
const jwt = require("jsonwebtoken");
const { doHash, doHashValidation } = require("../utils/hashing");
const AppError = require("../utils/AppError");

exports.registerUser = async (username, email, password) => {
  const userExists = await User.findOne({ email });
  if (userExists) {
    throw new AppError("Email already existed", 400);
  }

  const hashedPassword = await doHash(password, 12);

  const newUser = new User({
    username,
    email,
    password: hashedPassword,
  });

  const savedUser = await newUser.save();
  await Account.create({
    user_id: savedUser._id,
    name: "Cash",
    type: "Cash",
    init_balance: 0,
    current_balance: 0,
    isDefault: true,
  });

  return savedUser;
};

exports.loginUser = async (email, password) => {
  const user = await User.findOne({ email }).select("+password");
  if (!user) {
    throw new AppError("Email not found!", 400);
  }

  const validPassword = await doHashValidation(password, user.password);
  if (!validPassword) {
    throw new AppError("Invalid password", 400);
  }

  const token = jwt.sign({ _id: user._id }, process.env.JWT_SECRET, { expiresIn: "1d" });

  return { token, user };
};

exports.changeUserPassword = async (userId, oldPassword, newPassword) => {
  const user = await User.findById(userId).select("+password");
  if (!user) {
    throw new AppError("User not found", 404);
  }

  const matchPassword = await doHashValidation(oldPassword, user.password);
  if (!matchPassword) {
    throw new AppError("Old password doesn't match", 400);
  }

  if (oldPassword === newPassword) {
    throw new AppError("New password must be different from old password", 400);
  }

  const hashed = await doHash(newPassword, 12);
  user.password = hashed;

  await user.save();
};
