const Account = require("../models/account");
const AppError = require("../utils/AppError");

exports.getAccountsByUserId = async (userId) => {
  return await Account.find({ user_id: userId });
};

exports.createAccount = async (userId, data) => {
  const { name, type, init_balance } = data;
  const account = new Account({
    user_id: userId,
    name,
    type,
    init_balance,
    current_balance: init_balance,
    isDefault: false,
  });
  await account.save();
  return account;
};

exports.updateAccount = async (userId, accountId, data) => {
  const account = await Account.findOne({ _id: accountId, user_id: userId });
  if (!account) {
    throw new AppError("Account not found", 404);
  }

  if (account.isDefault) {
    if (data.name || data.type) {
      throw new AppError("Default account cannot be edited", 400);
    }
  }

  return await Account.findByIdAndUpdate(account._id, data, { new: true, runValidators: true });
};

exports.deleteAccount = async (userId, accountId) => {
  const account = await Account.findOne({ _id: accountId, user_id: userId });
  if (!account) {
    throw new AppError("Account not found", 404);
  }
  if (account.isDefault) {
    throw new AppError("Default account cannot be deleted", 400);
  }
  await account.deleteOne();
};
