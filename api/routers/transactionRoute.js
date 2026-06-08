const express = require("express");
const transactionController = require("../controllers/transactionController");
const auth = require("../middlewares/auth");
const { validate, transactionSchemas } = require("../middlewares/validator");

const route = express.Router();

route.post("/", auth, validate(transactionSchemas.create), transactionController.createTransaction);
route.get("/", auth, transactionController.getTransaction);
route.get("/:id", auth, transactionController.getTransactionById);
route.put("/:id", auth, validate(transactionSchemas.update), transactionController.updateTransaction);
route.delete("/:id", auth, transactionController.deleteTransaction);

module.exports = route;
