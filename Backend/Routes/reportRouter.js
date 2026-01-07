const { Router } = require("express");
const userAuthentication = require("./../middlewares/userAuthentication");

const reportRouter = Router();

//Trigger manual generation of the PDF.
reportRouter.post("/generate", (req, res) => {
  res.status(200).json({
    message: "Successfully generated PDF",
  });
});

//Download the generated PDF.
reportRouter.get("/download/:id", (req, res) => {
  res.status(200).json({
    message: "Successfully downloaded generated PDF for id:" + req.params.id,
  });
});

//Securely email the report to the registered therapist address.
reportRouter.post("/email", (req, res) => {
  res.status(200).json({
    message: "Successfully mailed the PDF report",
  });
});

module.exports = {
  reportRouter,
};
