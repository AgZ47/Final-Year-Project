const { Router } = require("express");

const userauthRouter = Router();

//User account register logic
userauthRouter.post("/register", (req, res) => {
  res.status(200).json({
    message: "User Registered Successfully",
  });
});

//User login logic
userauthRouter.post("/login", (req, res) => {
  res.status(200).json({
    message: "User Logged in Successfully",
  });
});

module.exports = {
  userauthRouter,
};
