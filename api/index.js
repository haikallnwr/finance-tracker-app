const express = require("express");
const connectDB = require("./config/db");
const cors = require("cors");
const helmet = require("helmet");
const mongoSanitize = require("express-mongo-sanitize");
const rateLimit = require("express-rate-limit");
const errorHandler = require("./middlewares/errorHandler");
const AppError = require("./utils/AppError");

require("dotenv").config();

const port = process.env.PORT || 3000;
const app = express();

const authRoute = require("./routers/authRoute");
const transactionRoute = require("./routers/transactionRoute");
const userRoute = require("./routers/userRoute");
const categoryRoute = require("./routers/categoryRoute");
const accountRoute = require("./routers/accountRoute");

app.use(helmet());
app.use(cors());

const limiter = rateLimit({
  max: 100,
  windowMs: 15 * 60 * 1000,
  message: "Too many requests from this IP, please try again in an hour!",
});
app.use("/api", limiter);

app.use(express.json({ limit: "10kb" }));

app.use(mongoSanitize());

connectDB();

app.get("/", (req, res) => {
  res.json({ message: "Hello There!" });
});

app.use("/api/auth", authRoute);
app.use("/api/transactions", transactionRoute);
app.use("/api/user", userRoute);
app.use("/api/category", categoryRoute);
app.use("/api/account", accountRoute);

app.use((req, res, next) => {
  next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

app.use(errorHandler);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
