const { Router } = require("express");

const interventionRouter = Router();

//Poll for any active intervention tasks (e.g., "Do breathing exercise").
interventionRouter.get("/current", (req, res) => {
  res.status(200).json({
    message: "Successfully polled for active intervention tasks",
  });
});

//User rates the help (e.g., "Did this help? Yes/No").
interventionRouter.post("/feedback", (req, res) => {
  res.status(200).json({
    message: "Successfully received feedback",
  });
});

module.exports = {
  interventionRouter,
};
