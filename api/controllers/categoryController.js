const categoryService = require("../services/categoryService");
const asyncHandler = require("express-async-handler");

exports.getCategories = asyncHandler(async (req, res) => {
  const category = await categoryService.getCategories(req.user._id);
  res.status(200).json(category);
});

exports.createCategory = asyncHandler(async (req, res) => {
  const category = await categoryService.createCategory(req.user._id, req.body);
  res.status(201).json({ message: "Category created", category });
});

exports.delete = asyncHandler(async (req, res) => {
  await categoryService.deleteCategory(req.user._id, req.params.id);
  res.status(200).json({ message: "Category deleted" });
});
