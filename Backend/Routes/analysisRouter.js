const { Router } = require("express");

const analysisRouter = Router();

//et the daily dashboard plan and mood score.
analysisRouter.get("/daily", (req, res) => {
  res.status(200).json({
    message: "Successfully sent daily report",
  });
});

module.exports = {
  analysisRouter,
};
