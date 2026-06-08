const Joi = require("joi");
const AppError = require("../utils/AppError");

const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      const errorMessage = error.details.map((detail) => detail.message).join(", ");
      return next(new AppError(errorMessage, 400));
    }
    next();
  };
};

const authSchemas = {
  register: Joi.object({
    username: Joi.string().required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(8).required(),
  }),
  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
  }),
  changePassword: Joi.object({
    oldPassword: Joi.string().required(),
    newPassword: Joi.string().min(8).required(),
  }),
};

const accountSchemas = {
  create: Joi.object({
    name: Joi.string().required(),
    type: Joi.string().required(),
    init_balance: Joi.number().required(),
    current_balance: Joi.number().required(),
    isDefault: Joi.boolean(),
  }),
  update: Joi.object({
    name: Joi.string(),
    type: Joi.string(),
    init_balance: Joi.number(),
    current_balance: Joi.number(),
    isDefault: Joi.boolean(),
  }),
};

const categorySchemas = {
  create: Joi.object({
    name: Joi.string().required(),
    type: Joi.string().valid("Income", "Expense", "Transfer").required(),
  }),
};

const transactionSchemas = {
  create: Joi.object({
    account_id: Joi.string().required(),
    category_id: Joi.string().required(),
    type: Joi.string().valid("Income", "Expense", "Transfer").required(),
    amount: Joi.number().min(0).required(),
    date: Joi.date().required(),
    note: Joi.string().allow("").optional(),
  }),
  update: Joi.object({
    account_id: Joi.string(),
    category_id: Joi.string(),
    type: Joi.string().valid("Income", "Expense", "Transfer"),
    amount: Joi.number().min(0),
    date: Joi.date(),
    note: Joi.string().allow("").optional(),
  }),
};

const userSchemas = {
  update: Joi.object({
    username: Joi.string().min(3),
    email: Joi.string().email(),
  }),
};

module.exports = {
  validate,
  authSchemas,
  accountSchemas,
  categorySchemas,
  transactionSchemas,
  userSchemas,
};
