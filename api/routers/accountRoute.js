const express = require("express");
const accountController = require("../controllers/accountController");
const auth = require("../middlewares/auth");
const { validate, accountSchemas } = require("../middlewares/validator");

const route = express.Router();

route.get("/", auth, accountController.getAccount);
route.post("/", auth, validate(accountSchemas.create), accountController.createAccount);
route.put("/:id", auth, validate(accountSchemas.update), accountController.updateAccount);
route.delete("/:id", auth, accountController.deleteAccount);

module.exports = route;
