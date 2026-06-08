const Transaction = require("../models/transaction");
const Account = require("../models/account");
const AppError = require("../utils/AppError");

exports.createTransaction = async (userId, data) => {
  const { account_id, category_id, type, amount, description, date } = data;
  const newTransaction = new Transaction({
    user_id: userId,
    account_id,
    category_id,
    type,
    amount,
    description,
    date,
  });
  await newTransaction.save();

  const account = await Account.findById(account_id);
  if (!account) {
    throw new AppError("Account not found", 404);
  }

  if (type === "Income") {
    account.current_balance += parseFloat(amount);
  } else {
    account.current_balance -= parseFloat(amount);
  }
  await account.save();

  return newTransaction;
};

exports.getTransactions = async (userId) => {
  return await Transaction.find({ user_id: userId })
    .populate("category_id", "name type")
    .populate("account_id", "name")
    .sort({ createdAt: -1 });
};

exports.getTransactionById = async (userId, transactionId) => {
  const transaction = await Transaction.findOne({
    _id: transactionId,
    user_id: userId,
  })
    .populate("category_id", "name type")
    .populate("account_id", "name");

  if (!transaction) {
    throw new AppError("Transaction not found", 404);
  }

  return transaction;
};

exports.updateTransaction = async (userId, transactionId, data) => {
  const oldTransaction = await Transaction.findOne({ _id: transactionId, user_id: userId });

  if (!oldTransaction) {
    throw new AppError("Transaction not found", 404);
  }

  const oldAccount = await Account.findById(oldTransaction.account_id);
  if (oldTransaction.type === "Income") {
    oldAccount.current_balance -= oldTransaction.amount;
  } else {
    oldAccount.current_balance += oldTransaction.amount;
  }
  await oldAccount.save();

  const updateTransaction = await Transaction.findByIdAndUpdate(transactionId, data, { new: true, runValidators: true });

  const newAccount = await Account.findById(updateTransaction.account_id);
  if (updateTransaction.type === "Income") {
    newAccount.current_balance += updateTransaction.amount;
  } else {
    newAccount.current_balance -= updateTransaction.amount;
  }
  await newAccount.save();

  return updateTransaction;
};

exports.deleteTransaction = async (userId, transactionId) => {
  const transaction = await Transaction.findOne({
    _id: transactionId,
    user_id: userId,
  });

  if (!transaction) {
    throw new AppError("Transaction not found", 404);
  }

  const account = await Account.findById(transaction.account_id);
  if (!account) {
    throw new AppError("Account not found", 404);
  }

  if (transaction.type === "Income") {
    account.current_balance -= transaction.amount;
  } else {
    account.current_balance += transaction.amount;
  }

  await account.save();
  await transaction.deleteOne();
};
