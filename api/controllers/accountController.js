const accountService = require("../services/accountService");
const asyncHandler = require("express-async-handler");

exports.getAccount = asyncHandler(async (req, res) => {
  const account = await accountService.getAccountsByUserId(req.user._id);
  res.status(200).json(account);
});

exports.createAccount = asyncHandler(async (req, res) => {
  const account = await accountService.createAccount(req.user._id, req.body);
  res.status(201).json({ message: "Account successfuly created", account });
});

exports.updateAccount = asyncHandler(async (req, res) => {
  const updated = await accountService.updateAccount(req.user._id, req.params.id, req.body);
  res.status(200).json({ message: "Account updated", account: updated });
});

exports.deleteAccount = asyncHandler(async (req, res) => {
  await accountService.deleteAccount(req.user._id, req.params.id);
  res.status(200).json({ message: "Account successfuly deleted" });
});
