const express = require("express");
const userController = require("../controllers/userController");
const auth = require("../middlewares/auth");
const { validate, userSchemas } = require("../middlewares/validator");
const route = express.Router();

route.get("/allUser", userController.getAllUser);
route.get("/myProfile", auth, userController.getUser);
route.put("/updateProfile", auth, validate(userSchemas.update), userController.updateUser);

module.exports = route;
