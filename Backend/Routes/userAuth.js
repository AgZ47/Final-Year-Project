const { Router } = require("express");
const z = require("zod");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

const userauthRouter = Router();

const JWT_SECRET = "HowToTrainYourDragon";

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
    data = await z.parse(inputModel, input);
  } catch (e) {
    return res.status(403).json({
      message: "failed to validate user",
    });
  }

  //validataion success check
  input.password = await bcrypt.hash(req.body.password, 10);
  console.log(data);

  return res.sendStatus(200);
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
      token: await jwt.sign(input.email, JWT_SECRET),
    })
    .json({
      message: "User Logged in Successfully",
    });
});

module.exports = {
  userauthRouter,
};
