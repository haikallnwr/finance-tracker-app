const transactionService = require("../services/transactionService");
const asyncHandler = require("express-async-handler");

exports.createTransaction = asyncHandler(async (req, res) => {
  const transaction = await transactionService.createTransaction(req.user._id, req.body);
  res.status(201).json({ message: "Transaction successfully created", transaction });
});

exports.getTransaction = asyncHandler(async (req, res) => {
  const transactions = await transactionService.getTransactions(req.user._id);
  res.status(200).json(transactions);
});

exports.getTransactionById = asyncHandler(async (req, res) => {
  const transaction = await transactionService.getTransactionById(req.user._id, req.params.id);
  res.status(200).json(transaction);
});

exports.updateTransaction = asyncHandler(async (req, res) => {
  const transaction = await transactionService.updateTransaction(req.user._id, req.params.id, req.body);
  res.status(200).json({ message: "Transaction updated", transaction });
});

exports.deleteTransaction = asyncHandler(async (req, res) => {
  await transactionService.deleteTransaction(req.user._id, req.params.id);
  res.status(200).json({ message: "Transaction deleted" });
});
