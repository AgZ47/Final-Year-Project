const express = require("express");
const { userauthRouter } = require("./Routes/userAuth");
const { userRouter } = require("./Routes/userRouter");
const { dataRouter } = require("./Routes/userData");
const { analysisRouter } = require("./Routes/analysisRouter");
const { interventionRouter } = require("./Routes/interventionRouter");
const { reportRouter } = require("./Routes/reportRouter");
require("dotenv").config();

const app = express();

app.use(express.json());

app.use("/auth", userauthRouter); //Create account, Get JWT Token.
app.use("/user", userRouter); //Set "Guardian" contacts and "Therapist Email".
app.use("/data", dataRouter); //Upload batched physiological data (HRV, Sleep), Upload text entry (triggers TFLite pre-processing first on phone), (High Priority) Immediate upload of a stress spike event.
app.use("/analysis", analysisRouter); //Get the daily dashboard plan and mood score.
app.use("/intervention", interventionRouter); //Poll for any active intervention tasks (e.g., "Do breathing exercise"), User rates the help (e.g., "Did this help? Yes/No").
app.use("/report", reportRouter); //Trigger manual generation of the PDF, Download the generated PDF, Securely email the report to the registered therapist address.

function main() {
  try {
    app.listen(3000);
    console.log("listening: Port 3000");
  } catch (e) {
    console.log("Launch Failed" + e);
  }
}

main();
