const express = require("express");
const authController = require("../controllers/authController");
const auth = require("../middlewares/auth");
const { validate, authSchemas } = require("../middlewares/validator");

const route = express.Router();

route.post("/register", validate(authSchemas.register), authController.register);
route.post("/login", validate(authSchemas.login), authController.login);
route.post("/logout", authController.logout);
route.put("/changePassword", auth, validate(authSchemas.changePassword), authController.changePassword);

module.exports = route;
