const { Router } = require("express");
const z = require("zod");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { dbclient } = require("../database/db");

const userauthRouter = Router();

//User account register logic
userauthRouter.post("/register", async (req, res) => {
  const input = req.body;

  //input validation based on defined schema
  const inputModel = z.object({
    username: z.string().min(3).max(100),
    email: z.email(),
    password: z.string().min(3).max(100),
  });

  try {
    data = inputModel.parse(input);
  } catch (e) {
    return res.status(403).json({
      message: "failed to validate user",
    });
  }

  //validataion success check
  input.password = await bcrypt.hash(req.body.password, 10);

  try {
    response = await dbclient.query(
      "INSERT INTO users (username, email, passwords) VALUES ($1, $2, $3) RETURNING id",
      [input.username, input.email, input.password]
    );

    return res.status(200).json({
      token: jwt.sign(response.rows[0].id, process.env.JWT_KEY),
    });
  } catch (e) {
    console.log(e);
    console.log("failed to get response from database");
    return res.sendStatus(400);
  }
});

//User login logic
userauthRouter.post("/login", async (req, res) => {
  const input = req.body;

  const inputModel = z.object({
    email: z.email(),
    password: z.string().min(3).max(100),
  });

  try {
    await z.parse(inputModel, input);
  } catch (e) {
    return res.status(403).json({
      message: "failed to validate input",
    });
  }

  res
    .status(200)
    .header({
      token: await jwt.sign(input.email, process.env.JWT_KEY),
    })
    .json({
      message: "User Logged in Successfully",
    });
});

module.exports = {
  userauthRouter,
};
