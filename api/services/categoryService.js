const Category = require("../models/category");
const AppError = require("../utils/AppError");

exports.getCategories = async (userId) => {
  return await Category.find({
    $or: [{ user_id: null }, { user_id: userId }],
  });
};

exports.createCategory = async (userId, data) => {
  const { name, type } = data;
  const category = new Category({
    user_id: userId,
    name,
    type,
  });
  await category.save();
  return category;
};

exports.deleteCategory = async (userId, categoryId) => {
  const deleted = await Category.findOneAndDelete({
    _id: categoryId,
    user_id: userId,
  });

  if (!deleted) {
    throw new AppError("Category not found", 404);
  }
};
