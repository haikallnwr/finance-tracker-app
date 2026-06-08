const mongoose = require("mongoose");
const Category = require("./models/category");
require("dotenv").config();

mongoose
  .connect(process.env.MONGO_URI)
  .then(async () => {
    console.log("Connected to DB");

    const defaultCategory = [
      { name: "Food & Drink", type: "Expense", user_id: null },
      { name: "Transport", type: "Expense", user_id: null },
      { name: "Shopping", type: "Expense", user_id: null },
      { name: "Bills", type: "Expense", user_id: null },
      { name: "Entertainment", type: "Expense", user_id: null },
      { name: "Health", type: "Expense", user_id: null },

      { name: "Salary", type: "Income", user_id: null },
      { name: "Freelance", type: "Income", user_id: null },
      { name: "Bonus", type: "Income", user_id: null },
      { name: "Gift", type: "Income", user_id: null },
    ];

    const exists = await Category.find({ user_id: null });

    if (exists.length > 0) {
      console.log("category already exists");
      process.exit();
    }

    await Category.insertMany(defaultCategory);
    console.log("catery successfuly insert");
    process.exit();
  })
  .catch((error) => {
    console.error(error);
    process.exit();
  });
