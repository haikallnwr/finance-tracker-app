const express = require("express");
const categoryController = require("../controllers/categoryController");
const auth = require("../middlewares/auth");
const { validate, categorySchemas } = require("../middlewares/validator");

const route = express.Router();

route.get("/", auth, categoryController.getCategories);
route.post("/", auth, validate(categorySchemas.create), categoryController.createCategory);
route.delete("/:id", auth, categoryController.delete);

module.exports = route;
