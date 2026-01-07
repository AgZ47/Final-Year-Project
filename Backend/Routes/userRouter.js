const { Router } = require("express");
const userAuthentication = require("./../middlewares/userAuthentication");

const userRouter = Router();

//Set "Guardian" contacts and "Therapist Email".
userRouter.post("/settings", (req, res) => {
  res.status(200).json({
    message: "Successfully changed User Settings",
  });
});

module.exports = {
  userRouter,
};
