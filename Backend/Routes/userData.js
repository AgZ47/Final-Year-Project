const { Router } = require("express");
const userAuthentication = require("./../middlewares/userAuthentication");

const dataRouter = Router();

//Upload batched physiological data (HRV, Sleep)
dataRouter.post("/sync", (req, res) => {
  res.status(200).json({
    message: "Successfully Uploaded data",
  });
});

//Upload text entry (triggers TFLite pre-processing first on phone).
dataRouter.post("/journal", (req, res) => {
  res.status(200).json({
    message: "Successfully uploaded journal entry",
  });
});

//(High Priority) Immediate upload of a stress spike event.
dataRouter.post("/emergency", (req, res) => {
  res.status(200).json({
    message: "Successfully uploaded stress spike event",
  });
});

module.exports = {
  dataRouter,
};
